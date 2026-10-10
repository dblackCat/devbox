import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const exec = promisify(execFile);

/** Корень окружения DevBox (родитель panel/) */
export const SERVER_ROOT = path.resolve(
	path.dirname(fileURLToPath(import.meta.url)),
	'../../../../..'
);

/** Выполнить shell-команду в login-shell (PATH + DOCKER_HOST из ~/.bashrc) */
export function sh(cmd: string, opts: { cwd?: string } = {}): Promise<{ stdout: string; stderr: string }> {
	return exec('/bin/bash', ['-lc', cmd], {
		cwd: opts.cwd ?? SERVER_ROOT,
		timeout: 5 * 60_000,
		maxBuffer: 20 * 1024 * 1024
	});
}
