<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		open = false,
		title,
		onclose,
		children,
		actions
	}: {
		open?: boolean;
		title?: string;
		onclose?: () => void;
		children?: Snippet;
		actions?: Snippet;
	} = $props();
</script>

{#if open}
	<div class="fixed inset-0 z-50 flex items-center justify-center">
		<!-- затемнение -->
		<button
			type="button"
			class="absolute inset-0 bg-black/70 backdrop-blur-[2px] cursor-default"
			onclick={() => onclose?.()}
			aria-label="Закрыть"
		></button>
		<div class="relative card w-full max-w-md shadow-2xl shadow-black/50 p-5" role="dialog">
			{#if title}
				<h3 class="text-sm font-semibold text-zinc-100 mb-3">{title}</h3>
			{/if}
			<div class="text-sm text-zinc-300">{@render children?.()}</div>
			{#if actions}
				<div class="flex justify-end gap-2 mt-5">{@render actions?.()}</div>
			{/if}
		</div>
	</div>
{/if}
