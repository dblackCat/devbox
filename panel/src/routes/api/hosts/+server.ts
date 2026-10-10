import { json } from '@sveltejs/kit';
import { listHosts, createHost, applyHosts } from '$lib/server/hosts';
import { readEnv } from '$lib/server/env';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async () => {
	const zone = readEnv().HOST_ZONE ?? 'dvl.to';
	return json({ hosts: listHosts(zone), zone });
};

export const POST: RequestHandler = async ({ request }) => {
	try {
		const { name, php } = await request.json();
		const output = await createHost(name, String(php));
		return json({ ok: true, output });
	} catch (e) {
		return json({ ok: false, error: String(e) }, { status: 400 });
	}
};

const PUT: RequestHandler = async () => {
	try {
		const output = await applyHosts();
		return json({ ok: true, output });
	} catch (e) {
		return json({ ok: false, error: String(e) }, { status: 500 });
	}
};
export { PUT };
