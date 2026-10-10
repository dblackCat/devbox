<script lang="ts">
	let {
		src,
		title = '',
		followable = false
	}: {
		/** URL, отдающий текст лога; поддерживает ?tail=N; для SSE-фоллоу — &follow=1 */
		src: string;
		title?: string;
		followable?: boolean;
	} = $props();

	let lines = $state<string[]>([]);
	let follow = $state(false);
	let paused = $state(false);
	let autoScroll = $state(true);
	let box: HTMLDivElement | undefined = $state();
	let es: EventSource | undefined = $state();

	async function loadTail() {
		const r = await fetch(src + (src.includes('?') ? '&' : '?') + 'tail=200');
		lines = (await r.text()).split('\n');
		scrollBottom();
	}

	function startFollow() {
		stopFollow();
		const url = src + (src.includes('?') ? '&' : '?') + 'tail=100&follow=1';
		es = new EventSource(url);
		es.onmessage = (e) => {
			if (paused) return;
			const chunk = JSON.parse(e.data) as string;
			lines = [...lines, ...chunk.split('\n')].slice(-1000);
			if (autoScroll) scrollBottom();
		};
		follow = true;
	}

	function stopFollow() {
		es?.close();
		es = undefined;
		follow = false;
	}

	function scrollBottom() {
		requestAnimationFrame(() => {
			if (box) box.scrollTop = box.scrollHeight;
		});
	}

	$effect(() => {
		loadTail();
		return () => stopFollow();
	});
</script>

<div class="p-3 space-y-2" onclick={(e) => e.stopPropagation()}>
	<div class="flex items-center justify-between gap-3">
		<span class="mono text-xs text-zinc-500 truncate">{title}</span>
		<div class="flex items-center gap-2 shrink-0">
			<label class="flex items-center gap-1.5 text-xs text-zinc-400 cursor-pointer">
				<input type="checkbox" bind:checked={autoScroll} class="accent-emerald-500" /> autoscroll
			</label>
			{#if followable}
				{#if follow}
					<button class="btn btn-ghost text-xs px-2 py-1" onclick={paused = (v) => !v}>
						{paused ? '▶ продолжить' : '⏸ пауза'}
					</button>
					<button class="btn btn-ghost text-xs px-2 py-1" onclick={stopFollow}>стоп</button>
				{:else}
					<button class="btn btn-default text-xs px-2 py-1" onclick={startFollow}>▶ follow</button>
				{/if}
			{/if}
			<button class="btn btn-ghost text-xs px-2 py-1" onclick={loadTail}>обновить</button>
		</div>
	</div>
	<div bind:this={box} class="terminal p-3 h-[45vh] whitespace-pre-wrap break-all">
		{#each lines as line, i (i)}{line + '\n'}{/each}
	</div>
</div>
