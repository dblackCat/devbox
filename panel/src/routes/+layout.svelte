<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import ConfirmModal from '$lib/components/ConfirmModal.svelte';
	import Button from '$lib/components/Button.svelte';
	import { api, pollJob, type Job } from '$lib/api';

	let { children } = $props();

	// --- состояние стека (шапка) ---
	let upCount = $state(0);
	let totalCount = $state(0);
	let confirmAction = $state<string | null>(null);
	let runningJob = $state<Job | null>(null);
	let jobError = $state('');

	const CONFIRMS: Record<string, { title: string; message: string; label: string }> = {
		restart: {
			title: 'Перезапустить окружение?',
			message: 'Все контейнеры будут перезапущены. Займёт ~10–20 секунд.',
			label: 'Перезапустить'
		},
		build: {
			title: 'Пересобрать окружение?',
			message:
				'Образы пересоберутся с нуля (без кэша), затем стек перезапустится. Это может занять несколько минут.',
			label: 'Пересобрать'
		},
		stop: {
			title: 'Остановить окружение?',
			message:
				'Все контейнеры будут остановлены, сайты и БД станут недоступны. Панель по http://localhost тоже погаснет — вернуть: прямой доступ http://localhost:8989 или just up.',
			label: 'Остановить'
		}
	};

	async function refreshStack() {
		try {
			const { containers } = await api.containers();
			totalCount = containers.length;
			upCount = containers.filter((c) => c.state === 'running').length;
		} catch {
			upCount = totalCount = 0;
		}
	}

	async function runAction() {
		const action = confirmAction!;
		confirmAction = null;
		jobError = '';
		try {
			const { jobId } = await api.startStack(action);
			runningJob = await pollJob(jobId, (j) => (runningJob = { ...j }));
			if (runningJob.status === 'error') jobError = `Ошибка: ${action}`;
		} catch (e) {
			jobError = String(e);
		}
		await refreshStack();
		setTimeout(() => (runningJob = null), 8000);
	}

	const nav = [
		{ href: '/', label: 'Dashboard' },
		{ href: '/containers', label: 'Containers' },
		{ href: '/logs', label: 'Logs' },
		{ href: '/hosts', label: 'Hosts' }
	];
	onMount(() => {
		refreshStack();
		const t = setInterval(refreshStack, 10_000);
		return () => clearInterval(t);
	});
</script>

<div class="min-h-screen">
	<header class="sticky top-0 z-40 border-b border-zinc-800 bg-zinc-950/90 backdrop-blur">
		<div
			class="mx-auto max-w-5xl px-4 h-[52px] flex items-center gap-4"
		>
			<a href="/" class="flex items-center gap-2 shrink-0">
				<span class="size-2 rounded-full {upCount === totalCount && totalCount > 0 ? 'bg-emerald-400' : 'bg-red-400'}"></span>
				<span class="font-semibold text-zinc-100">DevBox</span>
				<span class="mono text-xs text-zinc-500 hidden sm:inline">{upCount}/{totalCount}</span>
			</a>

			<nav class="flex items-center gap-1">
				{#each nav as n (n.href)}
					<a href={n.href} class="nav-link {page.url.pathname === n.href ? 'nav-link-active' : ''}">
						{n.label}
					</a>
				{/each}
			</nav>

			<div class="flex-1"></div>

			<div class="flex items-center gap-1.5">
				{#if runningJob}
					<span class="badge {runningJob.status === 'error' ? 'badge-down' : 'badge-warn'}">
						{#if runningJob.status === 'running'}
							<span class="size-1.5 rounded-full bg-amber-400 animate-pulse"></span>
						{/if}
						{runningJob.action}…
					</span>
				{/if}
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'restart')}>↻ Restart</Button>
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'build')}>⟳ Rebuild</Button>
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'stop')}>■ Stop</Button>
			</div>
		</div>
	</header>

	<main class="mx-auto max-w-5xl px-4 py-5">
		{@render children?.()}
	</main>
</div>

<ConfirmModal
	open={confirmAction !== null}
	title={confirmAction ? CONFIRMS[confirmAction].title : ''}
	message={confirmAction ? CONFIRMS[confirmAction].message : ''}
	confirmLabel={confirmAction ? CONFIRMS[confirmAction].label : ''}
	danger={confirmAction === 'stop' || confirmAction === 'build'}
	onconfirm={runAction}
	oncancel={() => (confirmAction = null)}
/>

<svelte:window onfocus={refreshStack} />
