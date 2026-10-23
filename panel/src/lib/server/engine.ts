import { execSync } from 'node:child_process';
import path from 'node:path';
import { SERVER_ROOT } from './sh';
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

/** Имя compose-проекта = префикс имён контейнеров (<project>-<сервис>-<n>) */
export function project(): string {
	const env = readEnv().COMPOSE_PROJECT_NAME;
	if (env) return env;
	return path.basename(SERVER_ROOT).toLowerCase().replace(/[^a-z0-9_-]/g, '') || 'server';
}

/** Regex для валидации имён контейнеров окружения */
export function containerNameRe(): RegExp {
	return new RegExp(`^${project()}-[a-z0-9-]+$`);
}
