<script lang="ts">
	import type { Snippet } from 'svelte';

	let {
		variant = 'default',
		size = 'md',
		loading = false,
		disabled = false,
		type = 'button',
		onclick,
		children,
		...rest
	}: {
		variant?: 'default' | 'primary' | 'danger' | 'ghost';
		size?: 'xs' | 'sm' | 'md';
		loading?: boolean;
		disabled?: boolean;
		type?: 'button' | 'submit';
		onclick?: (e: MouseEvent) => void;
		children?: Snippet;
		[x: string]: unknown;
	} = $props();

	const sizeCls = { xs: 'text-xs px-2 py-1', sm: 'text-xs px-2.5 py-1.5', md: 'text-sm px-3.5 py-2' }[size];
</script>

<button
	{type}
	class="btn btn-{variant} {sizeCls}"
	onclick={onclick}
	disabled={disabled || loading}
	{...rest}
>
	{#if loading}
		<span class="inline-block size-3 rounded-full border-2 border-current border-t-transparent animate-spin"></span>
	{/if}
	{@render children?.()}
</button>
