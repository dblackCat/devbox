<script lang="ts">
	import type { Connection } from '$lib/api';
	import CopyField from './CopyField.svelte';

	let { conn }: { conn: Connection } = $props();

	// строка подключения для dsn-подобного копирования
	let dsn = $derived(
		conn.id === 'redis'
			? `redis://${conn.host}:${conn.port}`
			: conn.id === 'manticore'
				? `${conn.host}:${conn.port}`
				: `${conn.host}:${conn.port} · ${conn.user}:${conn.password}`
	);
</script>

<div class="card p-3.5">
	<div class="flex items-center justify-between mb-2">
		<span class="text-xs font-semibold text-zinc-200">{conn.title}</span>
		<span class="text-[11px] text-zinc-600">{conn.note}</span>
	</div>
	<CopyField label="host" value={conn.host} />
	<CopyField label="port" value={conn.port} />
	{#if conn.user !== '—'}
		<CopyField label="user" value={conn.user} />
		<CopyField label="pass" value={conn.password} />
	{/if}
	<div class="mt-1.5 pt-1.5 border-t border-zinc-800/70">
		<CopyField label="всё" value={dsn} />
	</div>
</div>
