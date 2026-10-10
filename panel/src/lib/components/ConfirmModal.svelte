<script lang="ts">
	import Modal from './Modal.svelte';
	import Button from './Button.svelte';

	let {
		open = false,
		title = 'Подтвердите действие',
		message,
		confirmLabel = 'Подтвердить',
		danger = false,
		onconfirm,
		oncancel
	}: {
		open?: boolean;
		title?: string;
		message: string;
		confirmLabel?: string;
		danger?: boolean;
		onconfirm: () => void;
		oncancel?: () => void;
	} = $props();
</script>

<Modal {open} {title} onclose={() => oncancel?.()}>
	<p class="leading-relaxed">{message}</p>
	{#snippet actions()}
		<Button variant="ghost" size="sm" onclick={() => oncancel?.()}>Отмена</Button>
		<Button variant={danger ? 'danger' : 'primary'} size="sm" onclick={() => onconfirm?.()}>
			{confirmLabel}
		</Button>
	{/snippet}
</Modal>
