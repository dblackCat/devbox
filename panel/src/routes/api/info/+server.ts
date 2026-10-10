import { json } from '@sveltejs/kit';
import { info } from '$lib/server/env';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async () => json(info());
