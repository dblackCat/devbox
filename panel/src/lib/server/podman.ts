import { sh } from './sh';
import { engine } from './engine';

export interface Container {
	name: string;
	image: string;
	state: 'running' | 'exited' | 'other';
	status: string;
	ports: string;
}

/** Список контейнеров окружения (server-*) */
export async function listContainers(): Promise<Container[]> {
	const { stdout } = await sh(
		`${engine()} ps -a --filter name=server- --format '{{.Names}}\\t{{.Image}}\\t{{.State}}\\t{{.Status}}\\t{{.Ports}}'`
	);
	return stdout
		.split('\n')
		.filter(Boolean)
		.map((line) => {
			const [name, image, state, status, ports] = line.split('\t');
			return {
				name,
				image,
				state: state === 'running' ? 'running' : state === 'exited' ? 'exited' : 'other',
				status: status ?? '',
				ports: (ports ?? '').replace(/0\.0\.0\.0:/g, '')
			};
		})
		.sort((a, b) => a.name.localeCompare(b.name));
}

/** Действие над контейнером */
export async function containerAction(name: string, action: string) {
	if (!/^server-[a-z0-9-]+$/.test(name) || !['start', 'stop', 'restart'].includes(action)) {
		throw new Error('bad request');
	}
	await sh(`${engine()} ${action} ${name}`);
}
