// Tunt skal: läser env och delegerar till den testbara kärnan i _lib/handler.

import { handleChat } from './_lib/handler';
import type { Env, PagesFunction } from './_lib/types';

export const onRequestPost: PagesFunction<Env> = ({ request, env }) =>
  handleChat(request, env, (url, init) => fetch(url, init));
