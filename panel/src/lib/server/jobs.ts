import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { SERVER_ROOT } from './sh';
import { engine } from './engine';

export interface Job {
	id: string;
	action: string;
	status: 'running' | 'done' | 'error';
	output: string;
	startedAt: number;
}

const jobs = new Map<string, Job>();

function spawnJob(action: string, cmd: string): Job {
	const job: Job = { id: randomUUID().slice(0, 8), action, status: 'running', output: '', startedAt: Date.now() };
	jobs.set(job.id, job);
	if (jobs.size > 20) {
		const oldest = [...jobs.values()].sort((a, b) => a.startedAt - b.startedAt)[0];
		jobs.delete(oldest.id);
	}
	const child = spawn('/bin/bash', ['-lc', cmd], { cwd: SERVER_ROOT });
	const push = (d: Buffer) => {
		job.output += d.toString();
		if (job.output.length > 200_000) job.output = job.output.slice(-200_000);
	};
	child.stdout.on('data', push);
	child.stderr.on('data', push);
	child.on('close', (code) => {
		job.status = code === 0 ? 'done' : 'error';
		if (code !== 0) {
			console.error(`[job ${job.id}] ${job.action} exit=${code}\n${job.output}`);
		}
	});
	return job;
}

/** Команды строятся при запуске — ENGINE из .env подхватывается без рестарта панели */
const STACK_COMMANDS: Record<string, () => string> = {
	up: () => `${engine()} compose up -d && ${engine()} compose restart nginx`,
	stop: () => `${engine()} compose stop`,
	down: () => `${engine()} compose stop`, // алиас для CLI/скриптов
	restart: () => `${engine()} compose restart`,
	build: () =>
		`${engine()} compose build --no-cache && ${engine()} compose up -d && ${engine()} compose restart nginx`,
	xdebug_on: () => 'just xdebug debug || true',
	xdebug_off: () => 'just xdebug off || true'
};

export function startStackJob(action: string): Job {
	const cmd = STACK_COMMANDS[action]?.();
	if (!cmd) throw new Error(`Неизвестное действие: ${action}`);
	return spawnJob(action, cmd);
}

export function getJob(id: string): Job | undefined {
	return jobs.get(id);
}

/** Текущий статус: есть ли запущенные job'ы */
export function hasRunningJob(): boolean {
	return [...jobs.values()].some((j) => j.status === 'running');
}
