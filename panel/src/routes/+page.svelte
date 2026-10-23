<script lang="ts">
	import { onMount } from 'svelte';
	import { api, pollJob, type Container, type ToolLink, type Connection } from '$lib/api';
	import ServiceCard from '$lib/components/ServiceCard.svelte';
	import ConnectionCard from '$lib/components/ConnectionCard.svelte';
	import StatusBadge from '$lib/components/StatusBadge.svelte';

	let tools = $state<ToolLink[]>([]);
	let connections = $state<Connection[]>([]);
	let containers = $state<Container[]>([]);
	let xdebugMode = $state('off');
	let engineName = $state('');
	let xdebugBusy = $state(false);

	onMount(load);

	async function load() {
		const info = await api.info();
		tools = info.tools;
		connections = info.connections;
		xdebugMode = info.xdebugMode;
		engineName = info.engine;
		const { containers: c } = await api.containers();
		containers = c;
	}

	async function toggleXdebug() {
		xdebugBusy = true;
		const action = xdebugMode === 'off' ? 'xdebug_on' : 'xdebug_off';
		try {
			const { jobId } = await api.startStack(action);
			await pollJob(jobId, () => {});
			xdebugMode = xdebugMode === 'off' ? 'debug' : 'off';
			await api.containers();
		} finally {
			xdebugBusy = false;
		}
	}

	const upCount = $derived(containers.filter((c) => c.state === 'running').length);
</script>

<!-- статусная строка -->
<div class="flex items-center gap-3 mb-4 flex-wrap">
	<span class="badge {upCount === containers.length && containers.length ? 'badge-ok' : 'badge-down'}">
		<span class="size-1.5 rounded-full bg-current"></span>
		{upCount} / {containers.length} контейнеров
	</span>
	<button
		type="button"
		class="badge {xdebugMode === 'off' ? 'badge-muted' : 'badge-warn'} cursor-pointer hover:brightness-125"
		onclick={toggleXdebug}
		disabled={xdebugBusy}
		title="Переключить Xdebug"
	>
		Xdebug: {xdebugBusy ? '…' : xdebugMode} ⇄
	</button>
	<span class="flex-1"></span>
	<span class="text-xs text-zinc-600">окружение · {engineName || '…'} compose</span>
</div>

<!-- инструменты -->
<div class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
	{#each tools as t (t.id)}
		<ServiceCard tool={t} />
	{/each}
</div>

<!-- подключения -->
<h2 class="text-xs font-semibold uppercase tracking-wider text-zinc-500 mb-2">Подключения к сервисам</h2>
<div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mb-4">
	{#each connections as c (c.id)}
		<ConnectionCard conn={c} />
	{/each}
</div>

<!-- контейнеры компактно -->
<div class="flex items-center justify-between mb-2">
	<h2 class="text-xs font-semibold uppercase tracking-wider text-zinc-500">Контейнеры</h2>
	<a href="/containers" class="text-xs text-emerald-400 hover:text-emerald-300">логи и управление →</a>
</div>
<div class="card divide-y divide-zinc-800/80">
	{#each containers as c (c.name)}
		<a
			href="/containers?open={c.name}"
			class="flex items-center gap-3 px-3.5 py-2 hover:bg-zinc-900/60 transition-colors"
		>
			<StatusBadge state={c.state} />
			<span class="text-sm text-zinc-300">{c.name.replace(/^server-/, '').replace(/-1$/, '')}</span>
			<span class="mono text-xs text-zinc-600 truncate hidden md:inline">{c.image.replace('docker.io/library/', '')}</span>
			<span class="flex-1"></span>
			<span class="mono text-xs text-zinc-500">{c.status}</span>
		</a>
	{/each}
</div>
