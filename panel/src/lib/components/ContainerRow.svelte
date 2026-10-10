<script lang="ts">
	import type { Container } from '$lib/api';
	import StatusBadge from './StatusBadge.svelte';
	import Button from './Button.svelte';

	let {
		container,
		expanded = false,
		ontoggle,
		onaction,
		busy = false
	}: {
		container: Container;
		expanded?: boolean;
		ontoggle?: () => void;
		onaction?: (action: string) => void;
		busy?: boolean;
	} = $props();

	const short = $derived(container.name.replace(/^server-/, '').replace(/-1$/, ''));
</script>

<tr
	class="border-t border-zinc-800/80 hover:bg-zinc-900/60 cursor-pointer transition-colors {expanded ? 'bg-zinc-900/60' : ''}"
	onclick={ontoggle}
>
	<td class="px-3 py-2"><StatusBadge state={container.state} /></td>
	<td class="px-3 py-2 font-medium text-zinc-200 text-sm whitespace-nowrap">{short}</td>
	<td class="px-3 py-2 mono text-zinc-500 hidden md:table-cell">{container.image.replace('docker.io/library/', '')}</td>
	<td class="px-3 py-2 mono text-zinc-600 hidden lg:table-cell whitespace-nowrap">{container.ports}</td>
	<td class="px-3 py-2 text-right whitespace-nowrap" onclick={(e) => e.stopPropagation()}>
		<div class="inline-flex gap-1">
			{#if container.state === 'running'}
				<Button variant="ghost" size="xs" {busy} onclick={() => onaction?.('restart')}>restart</Button>
				<Button variant="ghost" size="xs" {busy} onclick={() => onaction?.('stop')}>stop</Button>
			{:else}
				<Button variant="ghost" size="xs" {busy} onclick={() => onaction?.('start')}>start</Button>
			{/if}
			<span class="text-xs text-zinc-500 self-center">{expanded ? '▲' : '▼'}</span>
		</div>
	</td>
</tr>
