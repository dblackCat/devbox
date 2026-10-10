import fs from 'node:fs';
import path from 'node:path';
import { json } from '@sveltejs/kit';
import { sh, SERVER_ROOT } from '$lib/server/sh';
import type { RequestHandler } from './$types';

const LOGS_ROOT = path.join(SERVER_ROOT, 'logs');

export interface LogFile {
	group: string;
	name: string;
	rel: string;
	size: number;
	mtime: number;
}

/** Список лог-файлов (logs/** + виртуальный лог панели) */
export const GET: RequestHandler = async ({ url }) => {
	if (url.searchParams.has('file')) {
		return readFile(
			url.searchParams.get('file')!,
			url.searchParams.has('download'),
			url.searchParams.get('tail')
		);
	}

	const files: LogFile[] = [];
	for (const group of fs.readdirSync(LOGS_ROOT)) {
		const dir = path.join(LOGS_ROOT, group);
		if (!fs.statSync(dir).isDirectory()) continue;
		for (const f of fs.readdirSync(dir)) {
			if (f.startsWith('.')) continue;
			const st = fs.statSync(path.join(dir, f));
			if (!st.isFile()) continue;
			files.push({ group, name: f, rel: `${group}/${f}`, size: st.size, mtime: st.mtimeMs });
		}
	}
	files.sort((a, b) => b.mtime - a.mtime);
	return json({ files });
};

function sanitize(rel: string): string | null {
	if (rel === 'panel') return 'panel';
	const abs = path.normalize(path.join(LOGS_ROOT, rel));
	if (!abs.startsWith(LOGS_ROOT + path.sep)) return null;
	if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) return null;
	return abs;
}

/** Очистка логов: truncate без удаления файлов (процессы продолжают писать в те же inode).
 *  target = путь файла из списка | 'all' — все файлы в logs/. Журнал панели очистить нельзя. */
export const POST: RequestHandler = async ({ request }) => {
	const { target } = await request.json();
	const cleared: string[] = [];

	const targets =
		target === 'all'
			? fs
					.readdirSync(LOGS_ROOT, { recursive: true })
					.filter((f) => {
						const abs = path.join(LOGS_ROOT, f as string);
						return fs.statSync(abs).isFile() && !path.basename(abs).startsWith('.');
					})
					.map((f) => path.join(LOGS_ROOT, f as string))
			: [sanitize(String(target))].filter((v): v is string => v !== null && v !== 'panel');

	if (!targets.length) return json({ ok: false, error: 'Нечего очищать' }, { status: 400 });
	for (const abs of targets) {
		fs.truncateSync(abs, 0);
		cleared.push(path.relative(LOGS_ROOT, abs));
	}
	return json({ ok: true, cleared });
};

async function readFile(rel: string, download: boolean, tail?: string | null) {
	const safe = sanitize(rel);
	if (!safe) return new Response('not found', { status: 404 });

	if (rel === 'panel') {
		const n = tail ? Math.min(parseInt(tail) || 500, 500) : 500;
		const { stdout } = await sh(`journalctl --user -u devbox-panel --no-pager -n ${n}`);
		return textOrDownload(stdout, 'devbox-panel.log', download);
	}

	let st = fs.statSync(safe);
	let start = 0;
	const maxTail = tail && !download ? parseInt(tail) : 0;
	if (maxTail && st.size > 512 * 1024) {
		// для страничного просмотра больших файлов — только хвост
		start = Math.max(0, st.size - 1024 * 1024);
	}
	if (st.size > 2 * 1024 * 1024) {
		start = st.size - 1024 * 1024;
		const fd = fs.openSync(safe, 'r');
		const probe = Buffer.alloc(4096);
		fs.readSync(fd, probe, 0, 4096, start);
		start += probe.indexOf('\n') + 1;
		fs.closeSync(fd);
		st = fs.statSync(safe);
	}
	const stream = fs.createReadStream(safe, { start });
	let body = await new Response(stream as any).text();
	if (maxTail) body = body.split('\n').slice(-maxTail).join('\n');
	const name = path.basename(safe);
	return textOrDownload(start > 0 ? `…[пропущено ${start} байт с начала]\n${body}` : body, name, download);
}

function textOrDownload(text: string, name: string, download: boolean) {
	const headers = { 'Content-Type': 'text/plain; charset=utf-8' };
	if (download) headers['Content-Disposition'] = `attachment; filename="${name}"` as any;
	return new Response(text, { headers });
}
