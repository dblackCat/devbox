import { sh } from '$lib/server/sh';
import { engine } from '$lib/server/engine';
import type { RequestHandler } from './$types';

/** Логи контейнера: ?tail=200 — срез, ?follow=1 — SSE-стрим */
export const GET: RequestHandler = async ({ params, url, request }) => {
	const name = params.name!;
	if (!/^server-[a-z0-9-]+$/.test(name)) return new Response('bad name', { status: 400 });
	const tail = url.searchParams.get('tail') ?? '200';

	if (url.searchParams.get('follow')) {
		const { spawn } = await import('node:child_process');
		const child = spawn('/bin/bash', ['-lc', `${engine()} logs -f --tail ${tail} ${name}`]);
		const stream = new ReadableStream({
			start(controller) {
				const enc = new TextEncoder();
				const send = (d: Buffer) =>
					controller.enqueue(enc.encode(`data: ${JSON.stringify(d.toString())}\n\n`));
				child.stdout.on('data', send);
				child.stderr.on('data', send);
				child.on('close', () => {
					controller.enqueue(enc.encode(`data: ${JSON.stringify('[конец стрима]')}\n\n`));
					controller.close();
				});
				request.signal.addEventListener('abort', () => child.kill());
			},
			cancel() {
				child.kill();
			}
		});
		return new Response(stream, {
			headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' }
		});
	}

	const { stdout, stderr } = await sh(`${engine()} logs --tail ${tail} ${name} 2>&1`);
	return new Response(stdout || stderr || '(пусто)', {
		headers: { 'Content-Type': 'text/plain; charset=utf-8' }
	});
};
