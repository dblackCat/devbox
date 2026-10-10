import { json } from '@sveltejs/kit';
import { startStackJob, getJob } from '$lib/server/jobs';
import type { RequestHandler } from './$types';

/** POST {action} -> {jobId}; GET ?id= -> статус job */
export const POST: RequestHandler = async ({ request }) => {
	try {
		const { action } = await request.json();
		const job = startStackJob(action);
		return json({ jobId: job.id });
	} catch (e) {
		return json({ error: String(e) }, { status: 400 });
	}
};

export const GET: RequestHandler = async ({ url }) => {
	const id = url.searchParams.get('id');
	const job = id ? getJob(id) : undefined;
	if (!job) return json({ error: 'not found' }, { status: 404 });
	return json(job);
};
