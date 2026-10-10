<script lang="ts">
	let {
		label,
		value = $bindable(''),
		placeholder,
		error,
		hint,
		type = 'text',
		id,
		suffix
	}: {
		label?: string;
		value?: string;
		placeholder?: string;
		error?: string;
		hint?: string;
		type?: string;
		id?: string;
		/** Неподвижный суффикс внутри поля справа (напр. ".dvl.to") */
		suffix?: string;
	} = $props();

	const uid = id ?? `f-${Math.random().toString(36).slice(2, 9)}`;
</script>

<div>
	{#if label}<label class="form-label" for={uid}>{label}</label>{/if}
	<div class="relative">
		<input {id} class="input {suffix ? 'pr-20' : ''}" {type} bind:value {placeholder} />
		{#if suffix}
			<span class="absolute inset-y-0 right-3 flex items-center pointer-events-none mono text-zinc-500">
				{suffix}
			</span>
		{/if}
	</div>
	{#if error}<p class="form-error">{error}</p>{/if}
	{#if hint && !error}<p class="text-xs text-zinc-500 mt-1">{hint}</p>{/if}
</div>
