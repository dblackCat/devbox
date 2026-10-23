import fs from 'node:fs';
import path from 'node:path';
import { SERVER_ROOT } from './sh';
import { engine } from './engine';

/** Прочитать .env окружения в объект */
export function readEnv(): Record<string, string> {
	const out: Record<string, string> = {};
	const file = path.join(SERVER_ROOT, '.env');
	if (!fs.existsSync(file)) return out;
	for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
		const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$/);
		if (m) out[m[1]] = m[2];
	}
	return out;
}

export interface ToolLink {
	id: string;
	title: string;
	desc: string;
	url: string;
	/** Ссылка с параметрами автовхода/предзаполнения */
	loginUrl: string;
	creds: { k: string; v: string }[];
}

/** Реквизиты S3 (SeaweedFS) из config/seaweedfs/s3.json */
function s3Creds(): { user: string; password: string } {
	try {
		const file = path.join(SERVER_ROOT, 'config', 'seaweedfs', 's3.json');
		const json = JSON.parse(fs.readFileSync(file, 'utf-8'));
		const c = json.identities?.[0]?.credentials?.[0];
		if (c) return { user: c.accessKey, password: c.secretKey };
	} catch { /* файла нет — дефолты */ }
	return { user: 'devbox', password: 'devbox-secret' };
}

/** Сводка для dashboard: ссылки, порты, реквизиты */
export function info() {
	const env = readEnv();
	const p = (k: string, d: string | number) => (env[k] ?? String(d));
	return {
		zone: env.HOST_ZONE ?? 'dvl.to',
		xdebugMode: env.XDEBUG_MODE ?? 'off',
		engine: engine(),
		tools: <ToolLink[]>[
			{
				id: 'pma',
				title: 'phpMyAdmin',
				desc: 'MySQL · веб-интерфейс',
				url: `http://localhost:${p('PMA_PORT', 8080)}`,
				// полный автовход (логин+пароль передаются в GET)
				loginUrl: `http://localhost:${p('PMA_PORT', 8080)}/?pma_username=root&pma_password=${encodeURIComponent(p('MYSQL_ROOT_PASSWORD', 'root'))}`,
				creds: [
					{ k: 'Сервер', v: 'mysql' },
					{ k: 'Логин', v: 'root' },
					{ k: 'Пароль', v: p('MYSQL_ROOT_PASSWORD', 'root') }
				]
			},
			{
				id: 'adminer',
				title: 'Adminer',
				desc: 'MySQL + PostgreSQL',
				url: `http://localhost:${p('ADMINER_PORT', 8081)}`,
				// пароль Adminer из GET не принимает — предзаполняем сервер/логин
				loginUrl: `http://localhost:${p('ADMINER_PORT', 8081)}/?server=mysql&username=root`,
				creds: [
					{ k: 'MySQL', v: 'root / ' + p('MYSQL_ROOT_PASSWORD', 'root') },
					{ k: 'PostgreSQL', v: 'postgres / ' + p('POSTGRES_PASSWORD', 'root') }
				]
			},
			{
				id: 'mailpit',
				title: 'Mailpit',
				desc: 'Перехват почты',
				url: `http://localhost:${p('MAILPIT_UI_PORT', 8025)}`,
				loginUrl: `http://localhost:${p('MAILPIT_UI_PORT', 8025)}`,
				creds: [
					{ k: 'SMTP', v: `mailpit:${p('MAILPIT_SMTP_PORT', 1025)} (без авторизации)` }
				]
			}
		],
		connections: [
			{
				id: 'mysql',
				title: 'MySQL 8.0',
				host: 'mysql',
				port: p('MYSQL_PORT', 3306),
				user: 'root',
				password: p('MYSQL_ROOT_PASSWORD', 'root'),
				note: 'внутри сети также алиас db'
			},
			{
				id: 'pg',
				title: 'PostgreSQL 17',
				host: 'postgres',
				port: p('PG_PORT', 5432),
				user: 'postgres',
				password: p('POSTGRES_PASSWORD', 'root'),
				note: 'внутри сети также алиас pg'
			},
			{
				id: 'redis',
				title: 'Redis 7',
				host: 'redis',
				port: p('REDIS_PORT', 6379),
				user: '—',
				password: '—',
				note: 'без пароля, persistence включён'
			},
			{
				id: 'manticore',
				title: 'Manticore',
				host: 'manticore',
				port: '9306 (SQL) / 9308 (HTTP)',
				user: '—',
				password: '—',
				note: 'поиск'
			},
			{
				id: 's3',
				title: 'S3 (SeaweedFS)',
				host: 's3',
				port: p('S3_PORT', 9000),
				user: s3Creds().user,
				password: s3Creds().password,
				note: 'S3-совместимое хранилище файлов; с хоста — http://127.0.0.1:' + p('S3_PORT', 9000)
			}
		]
	};
}
