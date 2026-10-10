/** Мини-клиент API панели + хелперы */

export interface Container {
	name: string;
	image: string;
	state: 'running' | 'exited' | 'other';
	status: string;
	ports: string;
}

export interface ToolLink {
	id: string;
	title: string;
	desc: string;
	url: string;
	loginUrl: string;
	creds: { k: string; v: string }[];
}

export interface Connection {
	id: string;
	title: string;
	host: string;
	port: string;
	user: string;
	password: string;
	note: string;
}

export interface HostItem {
	name: string;
	php: string;
	https: boolean;
}

export interface Job {
	id: string;
	action: string;
	status: 'running' | 'done' | 'error';
	output: string;
}

async function j<T>(url: string, init?: RequestInit): Promise<T> {
	const r = await fetch(url, init);
	return (await r.json()) as T;
}

export const api = {
	info: () => j<{ zone: string; xdebugMode: string; tools: ToolLink[]; connections: Connection[] }>('/api/info'),
	containers: () => j<{ containers: Container[] }>('/api/containers'),
	containerAction: (name: string, action: string) =>
		j<{ ok: boolean }>(`/api/containers/${name}/action`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ action })
		}),
	hosts: () => j<{ hosts: HostItem[]; zone: string }>('/api/hosts'),
	createHost: (name: string, php: string) =>
		j<{ ok: boolean; output?: string; error?: string }>('/api/hosts', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ name, php })
		}),
	applyHosts: () =>
		j<{ ok: boolean; output?: string }>('/api/hosts', { method: 'PUT' }),
	startStack: (action: string) =>
		j<{ jobId: string; error?: string }>('/api/stack', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ action })
		}),
	job: (id: string) => j<Job>(`/api/stack?id=${id}`)
};

/** Опрос job'а до завершения */
export async function pollJob(id: string, onTick: (job: Job) => void, everyMs = 1000): Promise<Job> {
	for (;;) {
		const job = await api.job(id);
		onTick(job);
		if (job.status !== 'running') return job;
		await new Promise((r) => setTimeout(r, everyMs));
	}
}
