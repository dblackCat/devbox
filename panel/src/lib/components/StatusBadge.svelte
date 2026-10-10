<script lang="ts">
	let { state }: { state: 'running' | 'exited' | 'other' | string } = $props();
</script>

{#if state === 'running'}
	<span class="badge badge-ok"><span class="size-1.5 rounded-full bg-emerald-400"></span>Up</span>
{:else if state === 'exited'}
	<span class="badge badge-down"><span class="size-1.5 rounded-full bg-red-400"></span>Down</span>
{:else}
	<span class="badge badge-warn">{state}</span>
{/if}
