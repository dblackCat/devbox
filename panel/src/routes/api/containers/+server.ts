import { json } from '@sveltejs/kit';
import { listContainers } from '$lib/server/podman';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async () => {
	try {
		return json({ containers: await listContainers() });
	} catch (e) {
		return json({ containers: [], error: String(e) }, { status: 500 });
	}
};
