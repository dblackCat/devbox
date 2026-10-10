<script lang="ts">
	import type { ToolLink } from '$lib/api';
	import CopyField from './CopyField.svelte';
	import Icon from './Icon.svelte';

	let { tool }: { tool: ToolLink } = $props();

	const ICONS: Record<string, string> = { pma: 'db', adminer: 'table', mailpit: 'mail' };
</script>

<div class="card p-4 flex flex-col gap-2.5">
	<div class="flex items-start justify-between gap-2">
		<div class="flex items-center gap-2.5 min-w-0">
			<span class="flex items-center justify-center size-8 rounded-md bg-zinc-800 text-zinc-400">
				<Icon name={ICONS[tool.id] ?? 'db'} size={16} />
			</span>
			<div>
				<a
					href={tool.loginUrl}
					target="_blank"
					rel="noreferrer"
					class="text-sm font-semibold text-zinc-100 hover:text-emerald-400 transition-colors"
				>
					{tool.title} ↗
				</a>
				<p class="text-xs text-zinc-500 mt-0.5">{tool.desc}</p>
			</div>
		</div>
		<span class="mono text-xs text-zinc-600 truncate shrink-0" title={tool.url}>
			{tool.url.replace('http://', '')}
		</span>
	</div>
	<div class="space-y-1 border-t border-zinc-800 pt-2.5">
		{#each tool.creds as c (c.k)}
			<CopyField label={c.k} value={c.v} />
		{/each}
	</div>
</div>
