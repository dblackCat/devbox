<script lang="ts">
	import { onMount } from 'svelte';
	import { api, type HostItem } from '$lib/api';
	import HostCard from '$lib/components/HostCard.svelte';
	import Input from '$lib/components/Input.svelte';
	import Select from '$lib/components/Select.svelte';
	import Button from '$lib/components/Button.svelte';

	let hosts = $state<HostItem[]>([]);
	let zone = $state('dvl.to');
	let name = $state('');
	let php = $state('82');
	let creating = $state(false);
	let formError = $state('');
	let banner = $state<{ text: string; needApply: boolean } | null>(null);
	let applying = $state(false);

	onMount(load);

	async function load() {
		const r = await api.hosts();
		hosts = r.hosts;
		zone = r.zone;
	}

	async function create() {
		formError = '';
		creating = true;
		try {
			const r = await api.createHost(name, php);
			if (r.ok) {
				banner = { text: `Хост ${name}.${zone} создан (${r.output?.split('\n')[0] ?? 'ok'})`, needApply: true };
				name = '';
				await load();
			} else {
				formError = r.error?.replace('Error: ', '') ?? 'ошибка';
			}
		} finally {
			creating = false;
		}
	}

	async function apply() {
		applying = true;
		try {
			const r = await api.applyHosts();
			banner = r.ok
				? { text: 'Nginx пересоздан — новый хост доступен по https', needApply: false }
				: { text: `Ошибка: ${r.output ?? ''}`, needApply: true };
		} finally {
			applying = false;
		}
	}
</script>

<h1 class="text-sm font-semibold text-zinc-100 mb-3">Хосты <span class="text-zinc-600 font-normal">· {hosts.length}</span></h1>

{#if banner}
	<div class="card p-3 mb-3 flex items-center gap-3 {banner.needApply ? 'border-amber-500/40' : 'border-emerald-500/40'}">
		<span class="text-sm {banner.needApply ? 'text-amber-300' : 'text-emerald-300'}">{banner.text}</span>
		{#if banner.needApply}
			<span class="flex-1"></span>
			<Button variant="primary" size="sm" loading={applying} onclick={apply}>Apply — перезапустить nginx</Button>
		{/if}
		<button class="btn btn-ghost px-2 py-0.5" onclick={() => (banner = null)}>✕</button>
	</div>
{/if}

<form class="card p-3 mb-4 flex flex-wrap items-end gap-3" onsubmit={(e) => { e.preventDefault(); create(); }}>
	<div class="flex-1 min-w-48">
		<Input label="Имя хоста" bind:value={name} placeholder="my-project" error={formError} suffix={`.${zone}`} />
	</div>
	<div class="w-36">
		<Select label="PHP" bind:value={php} options={[{ value: '80', label: 'PHP 8.0' }, { value: '82', label: 'PHP 8.2' }, { value: '84', label: 'PHP 8.4' }]} />
	</div>
	<Button type="submit" variant="primary" loading={creating} disabled={!name}>+ Создать</Button>
</form>

<div class="grid grid-cols-1 md:grid-cols-2 gap-2.5">
	{#each hosts as h (h.name)}
		<HostCard host={h} {zone} />
	{/each}
</div>
