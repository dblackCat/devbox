<script lang="ts">
	import { onMount } from 'svelte';
	import LogViewer from '$lib/components/LogViewer.svelte';
	import Button from '$lib/components/Button.svelte';
	import ConfirmModal from '$lib/components/ConfirmModal.svelte';

	interface LogFile {
		group: string;
		name: string;
		rel: string;
		size: number;
		mtime: number;
	}

	let files = $state<LogFile[]>([]);
	let selected = $state<string | null>(null);
	let confirm: { target: string; title: string; message: string } | null = null;
	let clearing = $state(false);

	onMount(load);

	async function load() {
		const r = await fetch('/api/logs');
		const d = (await r.json()) as { files: LogFile[] };
		files = d.files;
		if (!selected && d.files.length) selected = d.files[0].rel;
	}

	async function clearLogs() {
		const { target } = confirm!;
		confirm = null;
		clearing = true;
		try {
			await fetch('/api/logs', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ target })
			});
			await load();
		} finally {
			clearing = false;
		}
	}

	const groups = $derived([...new Set(files.map((f) => f.group))]);
	const selectedIsPanel = $derived(selected === 'panel');

	function fmtSize(bytes: number) {
		if (bytes > 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB';
		if (bytes > 1024) return (bytes / 1024).toFixed(0) + ' KB';
		return bytes + ' B';
	}
</script>

{#if files.length === 0}
	<!-- пустое состояние: файлов ещё нет -->
	<div class="flex flex-col items-center justify-center min-h-[60vh] gap-3 text-center px-6">
		<span class="text-4xl">🗒️</span>
		<h2 class="text-sm font-semibold text-zinc-300">Логи ещё не сформированы</h2>
		<p class="text-sm text-zinc-500 max-w-md leading-relaxed">
			Файлы создаются по мере появления записей: access-лог nginx — после первых запросов,
			логи PHP — при первых ошибках. Если файлов нет — значит, ошибок пока не было.
			Обновите страницу после обращения к сайтам.
		</p>
		<Button variant="default" size="sm" onclick={load}>Обновить</Button>
	</div>
{:else}
	<div class="flex items-center justify-between mb-3 gap-2 flex-wrap">
		<h1 class="text-sm font-semibold text-zinc-100">Логи окружения</h1>
		<div class="flex items-center gap-3">
			<a
				href="/api/logs?file={selected}&download=1"
				class="text-xs text-emerald-400 hover:text-emerald-300">				скачать выбранный ↓</a
			>
			{#if selected && !selectedIsPanel}
				<button
					class="text-xs text-amber-400 hover:text-amber-300 disabled:opacity-40"
					disabled={clearing}
					onclick={() =>
						(confirm = {
							target: selected!,
							title: 'Очистить лог?',
							message: `Файл ${selected} будет обнулён (не удалён — процесс продолжит писать в него).`
						})}
				>
					очистить
				</button>
			{/if}
			<button
				class="text-xs text-red-400 hover:text-red-300 disabled:opacity-40"
				disabled={clearing}
				onclick={() =>
					(confirm = {
						target: 'all',
						title: 'Очистить все логи?',
						message:
							'Все файлы в logs/ будут обнулены (файлы не удаляются, сервисы продолжат запись). Журнал панели не затрагивается.'
					})}
			>
				очистить все
			</button>
		</div>
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
				<p class="p-4 text-sm text-zinc-500">Файл не выбран</p>
			{/if}
		</div>
	</div>
{/if}

<ConfirmModal
	open={confirm !== null}
	title={confirm?.title ?? ''}
	message={confirm?.message ?? ''}
	confirmLabel="Очистить"
	danger={true}
	onconfirm={clearLogs}
	oncancel={() => (confirm = null)}
/>
