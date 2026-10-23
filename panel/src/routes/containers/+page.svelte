<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { api, type Container } from '$lib/api';
	import ContainerRow from '$lib/components/ContainerRow.svelte';
	import CopyField from '$lib/components/CopyField.svelte';
	import LogViewer from '$lib/components/LogViewer.svelte';

	let containers = $state<Container[]>([]);
	let engineName = $state('');
	let expanded = $state<string | null>(null);
	let busyName = $state('');
	let error = $state('');

	onMount(() => {
		load();
		const t = setInterval(load, 5000);
		return () => clearInterval(t);
	});

	async function load() {
		try {
			const r = await api.containers();
			containers = r.containers;
			if (!engineName) engineName = (await api.info()).engine;
		} catch (e) {
			error = String(e);
		}
	}

	// ?open=server-xxx-1 из dashboard — раскрыть сразу
	$effect(() => {
		const open = page.url.searchParams.get('open');
		if (open && containers.some((c) => c.name === open)) expanded = open;
	});

	async function action(name: string, act: string) {
		busyName = name;
		try {
			await api.containerAction(name, act);
			await load();
		} finally {
			busyName = '';
		}
	}
</script>

<div class="flex items-center justify-between mb-3">
	<h1 class="text-sm font-semibold text-zinc-100">Контейнеры</h1>
	<span class="text-xs text-zinc-600">клик по строке — логи · обновление 5с</span>
</div>

{#if error}
	<div class="card p-4 text-sm text-red-400 mb-3">{error}</div>
{/if}

<div class="card overflow-hidden">
	<table class="w-full">
		<thead>
			<tr class="text-left text-[11px] uppercase tracking-wider text-zinc-600 bg-zinc-900/80">
				<th class="px-3 py-2 font-medium w-20"></th>
				<th class="px-3 py-2 font-medium">Имя</th>
				<th class="px-3 py-2 font-medium hidden md:table-cell">Образ</th>
				<th class="px-3 py-2 font-medium hidden lg:table-cell">Порты</th>
				<th class="px-3 py-2 font-medium text-right w-56"></th>
			</tr>
		</thead>
		<tbody>
			{#each containers as c (c.name)}
				<ContainerRow
					container={c}
					expanded={expanded === c.name}
					busy={busyName === c.name}
					ontoggle={() => (expanded = expanded === c.name ? null : c.name)}
					onaction={(a) => action(c.name, a)}
				/>
				{#if expanded === c.name}
					{@const service = c.name.replace(/^[^-]+-/, '').replace(/-1$/, '')}
					<tr class="border-t border-zinc-800/80">
						<td colspan="5" class="p-0 bg-zinc-950/50">
							<div class="px-3 pt-3 grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-1">
								<CopyField label="вход (just)" value={`just sh ${service}`} />
								<CopyField label={`вход (${engineName || 'движок'})`} value={`${engineName || 'podman'} exec -it ${c.name} bash`} />
							</div>
							<LogViewer src={`/api/containers/${c.name}/logs`} title={c.name} followable={true} />
						</td>
					</tr>
				{/if}
			{/each}
		</tbody>
	</table>
</div>
