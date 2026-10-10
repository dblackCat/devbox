<script lang="ts">
	let { label, value }: { label: string; value: string } = $props();

	let copied = $state(false);

	async function copy() {
		await navigator.clipboard.writeText(value);
		copied = true;
		setTimeout(() => (copied = false), 1200);
	}
</script>

<div class="flex items-center justify-between gap-2 min-w-0">
	<span class="text-xs text-zinc-500 shrink-0">{label}</span>
	<span class="mono truncate flex-1 text-right" title={value}>{value}</span>
	<button
		type="button"
		class="btn btn-ghost px-1.5 py-0.5 text-xs shrink-0"
		onclick={copy}
		title="Копировать"
	>
		{copied ? '✓' : '⧉'}
	</button>
</div>
