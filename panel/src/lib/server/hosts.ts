import fs from 'node:fs';
import path from 'node:path';
import { sh, SERVER_ROOT } from './sh';
import { listContainers } from './podman';
import { engine, project } from './engine';

export interface Host {
	name: string;
	php: string;
	https: boolean;
}

/** Доступные версии PHP — из запущенных контейнеров (server-php8X) */
export async function phpVersions(): Promise<string[]> {
	const containers = await listContainers();
	const versions = new Set<string>();
	for (const c of containers) {
		const m = c.name.match(new RegExp(`^${project()}-php(\\d+)-\\d+$`));
		if (m) versions.add(m[1]);
	}
	return [...versions].sort();
}

export function listHosts(zone: string): Host[] {
	const dir = path.join(SERVER_ROOT, 'hosts');
	return fs
		.readdirSync(dir)
		.filter((f) => fs.existsSync(path.join(dir, f, 'nginx.conf')))
		.map((name) => {
			const conf = fs.readFileSync(path.join(dir, name, 'nginx.conf'), 'utf8');
			const php = conf.match(/fastcgi_pass\s+php(\d+)/)?.[1] ?? '82';
			return { name, php, https: conf.includes('listen 443 ssl') };
		})
		.sort((a, b) => a.name.localeCompare(b.name));
}

export async function createHost(name: string, php: string): Promise<string> {
	if (!/^[a-z0-9][a-z0-9-]{1,30}$/.test(name)) {
		throw new Error('Имя: 2-31 символ, [a-z0-9-]');
	}
	const available = await phpVersions();
	if (!available.includes(php)) {
		throw new Error(`PHP ${php} недоступен. Доступны: ${available.join(', ')}`);
	}
	const exists = fs.existsSync(path.join(SERVER_ROOT, 'hosts', name));
	if (exists) throw new Error(`Хост "${name}" уже существует`);
	const { stdout } = await sh(`./scripts/devbox-host.sh ${name} php${php}`);
	return stdout.trim();
}

/** Применить новые алиасы: пересоздать nginx */
export async function applyHosts(): Promise<string> {
	const { stdout } = await sh(`${engine()} compose up -d nginx 2>&1 && ${engine()} compose restart nginx`);
	return stdout.trim();
}
