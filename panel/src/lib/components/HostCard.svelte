<script lang="ts">
	import type { HostItem } from '$lib/api';
	import CopyField from './CopyField.svelte';

	let { host, zone }: { host: HostItem; zone: string } = $props();

	const url = $derived(`https://${host.name}.${zone}`);
	const path = $derived(`/var/www/${host.name}`);
</script>

<div class="card px-3.5 py-3 flex flex-col gap-2 hover:border-zinc-600 transition-colors">
	<a
		href={url}
		target="_blank"
		rel="noreferrer"
		class="flex items-center justify-between gap-3 group min-w-0"
	>
		<span class="text-sm font-medium text-zinc-200 group-hover:text-emerald-400 transition-colors truncate">
			{host.name}<span class="text-zinc-600">.{zone}</span> ↗
		</span>
		<span class="flex items-center gap-2 shrink-0">
			<span class="badge badge-muted">PHP {host.php}</span>
			{#if host.https}<span class="badge badge-ok">https</span>{/if}
		</span>
	</a>
	<div onclick={(e) => e.stopPropagation()}>
		<CopyField label="путь" value={path} />
	</div>
</div>
