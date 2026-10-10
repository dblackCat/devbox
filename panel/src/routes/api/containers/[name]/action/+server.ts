import { json } from '@sveltejs/kit';
import { containerAction } from '$lib/server/podman';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ params, request }) => {
	try {
		const { action } = await request.json();
		await containerAction(params.name!, action);
		return json({ ok: true });
	} catch (e) {
		return json({ ok: false, error: String(e) }, { status: 400 });
	}
};
