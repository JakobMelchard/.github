import { DurableObject } from "cloudflare:workers";

export class Smoke extends DurableObject {
  async fetch() {
    return new Response("ok");
  }
}

export default {
  async fetch(request, env) {
    return env.SMOKE.get(env.SMOKE.idFromName("smoke")).fetch(request);
  },
};
