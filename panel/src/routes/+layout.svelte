<script lang="ts">
	import '../app.css';
	import { page } from '$app/state';
	import { onMount } from 'svelte';
	import ConfirmModal from '$lib/components/ConfirmModal.svelte';
	import Button from '$lib/components/Button.svelte';
	import Icon from '$lib/components/Icon.svelte';
	import { api, pollJob, type Job, type ToolLink } from '$lib/api';

	let { children } = $props();

	// --- состояние стека (шапка) ---
	let upCount = $state(0);
	let totalCount = $state(0);
	let tools = $state<ToolLink[]>([]);
	let confirmAction = $state<string | null>(null);
	let runningJob = $state<Job | null>(null);

	const CONFIRMS: Record<string, { title: string; message: string; label: string }> = {
		up: {
			title: 'Запустить окружение?',
			message: 'Стек будет запущен (образы уже собраны). Займёт 10–30 секунд.',
			label: 'Запустить'
		},
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
				'Все контейнеры будут остановлены (займёт до минуты), сайты и БД станут недоступны. Панель по http://localhost тоже погаснет — вернуть: прямой доступ http://localhost:8989 и кнопка запуска, или just up.',
			label: 'Остановить'
		}
	};

	const NAV = [
		{ href: '/', label: 'Dashboard', icon: 'grid' },
		{ href: '/containers', label: 'Containers', icon: 'box' },
		{ href: '/logs', label: 'Logs', icon: 'file' },
		{ href: '/hosts', label: 'Hosts', icon: 'globe' }
	];

	const TOOL_ICONS: Record<string, string> = { pma: 'db', adminer: 'table', mailpit: 'mail' };

	async function refreshStack() {
		try {
			const { containers } = await api.containers();
			totalCount = containers.length;
			upCount = containers.filter((c) => c.state === 'running').length;
		} catch {
			upCount = totalCount = 0;
		}
	}

	onMount(() => {
		refreshStack();
		api.info().then((i) => (tools = i.tools)).catch(() => {});
		const t = setInterval(refreshStack, 10_000);
		return () => clearInterval(t);
	});

	// --- таймер выполняемого job'а ---
	let elapsed = $state(0);
	let elapsedTimer: ReturnType<typeof setInterval> | undefined;

	$effect(() => {
		if (runningJob?.status === 'running') {
			elapsed = Math.round((Date.now() - runningJob.startedAt) / 1000);
			clearInterval(elapsedTimer);
			elapsedTimer = setInterval(() => (elapsed = Math.round((Date.now() - runningJob!.startedAt) / 1000)), 1000);
		} else {
			clearInterval(elapsedTimer);
		}
		return () => clearInterval(elapsedTimer);
	});

	async function runAction() {
		const action = confirmAction!;
		confirmAction = null;
		try {
			const res = await api.startStack(action);
			if (!res.jobId) throw new Error(res.error ?? 'не удалось запустить действие');
			runningJob = await pollJob(res.jobId, (j) => (runningJob = { ...j }));
		} catch {
			// при stop/down nginx гаснет вместе со стеком — потеря связи это ожидаемый исход,
			// для остальных действий (up/restart/build) поллинг уже ретраился 15с — это реальная ошибка
			const expected = action === 'stop' || action === 'down';
			runningJob = {
				id: 'err',
				action,
				status: expected ? 'done' : 'error',
				output: expected ? 'окружение останавливается — панель: localhost:8989' : 'потеряна связь',
				startedAt: Date.now()
			};
		}
		await refreshStack().catch(() => {});
		setTimeout(() => (runningJob = null), 8000);
	}
</script>

<div class="min-h-screen">
	<header class="sticky top-0 z-40 border-b border-zinc-800 bg-zinc-950/90 backdrop-blur">
		<!-- строка 1: лого + индикатор + быстрые ссылки инструментов -->
		<div class="mx-auto max-w-5xl px-4 h-10 flex items-center gap-3">
			<a href="/" class="flex items-center gap-2 shrink-0">
				<span
					class="size-2 rounded-full {upCount === totalCount && totalCount > 0
						? 'bg-emerald-400'
						: 'bg-red-400'}"
				></span>
				<span class="font-semibold text-zinc-100">DevBox</span>
				<span class="mono text-xs text-zinc-500">{upCount}/{totalCount}</span>
			</a>

			<div class="flex-1"></div>

			<nav class="flex items-center gap-1">
				{#each tools as t (t.id)}
					<a
						href={t.loginUrl}
						target="_blank"
						rel="noreferrer"
						class="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium text-zinc-400
							hover:text-zinc-100 hover:bg-zinc-800/60 transition-colors"
						title={t.url + (t.id === 'pma' ? ' · автовход' : '')}
					>
						<Icon name={TOOL_ICONS[t.id] ?? 'db'} size={13} />
						{t.title}
						↗
					</a>
				{/each}
			</nav>
		</div>

		<!-- строка 2: меню страниц + глобальные действия -->
		<div class="mx-auto max-w-5xl px-4 h-11 flex items-center gap-4 border-t border-zinc-800/60">
			<nav class="flex items-center gap-1">
				{#each NAV as n (n.href)}
					<a
						href={n.href}
						class="nav-link flex items-center gap-1.5 {page.url.pathname === n.href ? 'nav-link-active' : ''}"
					>
						<Icon name={n.icon} size={13} />
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
							{runningJob.action} {elapsed}s…
						{:else}
							{runningJob.action} {runningJob.status === 'done' ? '✓' : '✗'}
						{/if}
					</span>
				{/if}
				{#if totalCount === 0}
					<Button variant="primary" size="sm" onclick={() => (confirmAction = 'up')}>
						▶ Start
					</Button>
				{/if}
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'restart')}>
					<Icon name="rotate" size={12} /> Restart
				</Button>
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'build')}>
					<Icon name="hammer" size={12} /> Rebuild
				</Button>
				<Button variant="ghost" size="sm" onclick={() => (confirmAction = 'stop')}>
					<Icon name="square" size={12} /> Stop
				</Button>
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
