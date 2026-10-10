<script lang="ts">
	let {
		label,
		value = $bindable(''),
		options,
		id
	}: {
		label?: string;
		value?: string;
		options: { value: string; label: string }[];
		id?: string;
	} = $props();

	const uid = id ?? `s-${Math.random().toString(36).slice(2, 9)}`;
</script>

<div>
	{#if label}<label class="form-label" for={uid}>{label}</label>{/if}
	<select {id} class="select" bind:value>
		{#each options as o (o.value)}
			<option value={o.value}>{o.label}</option>
		{/each}
	</select>
</div>
