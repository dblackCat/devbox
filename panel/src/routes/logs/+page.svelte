<script lang="ts">
	import { onMount } from 'svelte';
	import LogViewer from '$lib/components/LogViewer.svelte';
	import StatusBadge from '$lib/components/StatusBadge.svelte';

	interface LogFile {
		group: string;
		name: string;
		rel: string;
		size: number;
		mtime: number;
	}

	let files = $state<LogFile[]>([]);
	let selected = $state<string | null>(null);

	onMount(load);

	async function load() {
		const r = await fetch('/api/logs');
		const d = (await r.json()) as { files: LogFile[] };
		files = d.files;
		if (!selected && d.files.length) selected = d.files[0].rel;
	}

	const groups = $derived([...new Set(files.map((f) => f.group))]);

	function fmtSize(bytes: number) {
		if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB';
		if (bytes > 1024) return (bytes / 1024).toFixed(0) + ' KB';
		return bytes + ' B';
	}
</script>

<div class="flex items-center justify-between mb-3">
	<h1 class="text-sm font-semibold text-zinc-100">Логи окружения</h1>
	<a
		href="/api/logs?file={selected}&download=1"
		class="text-xs text-emerald-400 hover:text-emerald-300"
	>скачать выбранный ↓</a
	>
</div>

<div class="grid grid-cols-[220px_1fr] gap-3 items-start">
	<div class="card divide-y divide-zinc-800/80 max-h-[75vh] overflow-y-auto">
		{#each groups as g (g)}
			<div>
				<div class="px-3 pt-2 pb-1 text-[11px] uppercase tracking-wider text-zinc-600">{g}</div>
				{#each files.filter((f) => f.group === g) as f (f.rel)}
					<button
						class="w-full text-left px-3 py-1.5 text-sm transition-colors flex items-center justify-between gap-2 cursor-pointer
							{selected === f.rel ? 'bg-zinc-800 text-zinc-100' : 'text-zinc-400 hover:bg-zinc-900/60 hover:text-zinc-200'}"
						onclick={() => (selected = f.rel)}
					>
						<span class="truncate mono text-[13px]">{f.name}</span>
						<span class="text-[10px] text-zinc-600 shrink-0">{fmtSize(f.size)}</span>
					</button>
				{/each}
			</div>
		{/each}
	</div>

	<div class="card">
		{#if selected}
			<LogViewer src={'/api/logs?file=' + encodeURIComponent(selected)} title={selected} />
		{:else}
			<p class="p-4 text-sm text-zinc-500">Нет лог-файлов</p>
		{/if}
	</div>
</div>
