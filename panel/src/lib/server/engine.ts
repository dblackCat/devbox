import { execSync } from 'node:child_process';
import { readEnv } from './env';

let cached: string | null = null;

/** Контейнерный движок: ENGINE из .env окружения, иначе автоопределение (podman | docker) */
export function engine(): string {
	if (cached) return cached;
	const e = readEnv().ENGINE;
	if (e === 'podman' || e === 'docker') {
		cached = e;
		return cached;
	}
	try {
		execSync('command -v podman', { stdio: 'ignore', shell: '/bin/bash' });
		cached = 'podman';
	} catch {
		cached = 'docker';
	}
	return cached;
}
