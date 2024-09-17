import { createApp } from 'vue';
import { createI18n } from 'vue-i18n';

import axios from 'axios';
// Global Components
import hljsVuePlugin from '@highlightjs/vue-plugin';

import Multiselect from 'vue-multiselect';
// import VueFormulate from '@braid/vue-formulate';
import { plugin, defaultConfig } from '@formkit/vue';
import WootSwitch from 'components/ui/Switch.vue';
import WootWizard from 'components/ui/Wizard.vue';
import { sync } from 'vuex-router-sync';
import FloatingVue from 'floating-vue';
import WootUiKit from 'dashboard/components';
import App from 'dashboard/App.vue';
import i18nMessages from 'dashboard/i18n';
import createAxios from 'dashboard/helper/APIHelper';

import commonHelpers, { isJSONValid } from 'dashboard/helper/commons';
import router, { initalizeRouter } from 'dashboard/routes';
import store from 'dashboard/store';
import constants from 'dashboard/constants/globals';
import * as Sentry from '@sentry/vue';
// import { Integrations } from '@sentry/tracing';
import {
  initializeAnalyticsEvents,
  initializeChatwootEvents,
} from 'dashboard/helper/scriptHelpers.js';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';

import resizeDirective from 'dashboard/helper/directives/resize.js';
import { directive as onClickaway } from 'vue3-click-away';

import 'floating-vue/dist/style.css';

const i18n = createI18n({
  legacy: false, // https://github.com/intlify/vue-i18n/issues/1902
  locale: 'en',
  messages: i18nMessages,
});

const app = createApp(App);
app.use(i18n);
app.use(store);
app.use(router);

// This is used in dashboard/helper/actionCable.js
// Since `app` is not available, we make a "fake" app with $store property
window.WOOT_STORE = store;

// [VITE] Disabled this, need to renable later
if (window.errorLoggingConfig) {
  Sentry.init({
    app,
    dsn: window.errorLoggingConfig,
    denyUrls: [
      // Chrome extensions
      /^chrome:\/\//i,
      /chrome-extension:/i,
      /extensions\//i,

      // Locally saved copies
      /file:\/\//i,

      // Safari extensions.
      /safari-web-extension:/i,
      /safari-extension:/i,
    ],
    integrations: [Sentry.browserTracingIntegration({ router })],
    ignoreErrors: [
      'ResizeObserver loop completed with undelivered notifications',
    ],
  });
}

app.use(VueDOMPurifyHTML, domPurifyConfig);
app.use(WootUiKit);
app.use(
  plugin,
  defaultConfig({
    rules: {
      JSON: ({ value }) => isJSONValid(value),
    },
  })
);
app.use(FloatingVue);
app.use(hljsVuePlugin);

app.component('multiselect', Multiselect);
app.component('woot-switch', WootSwitch);
app.component('woot-wizard', WootWizard);
app.component('fluent-icon', FluentIcon);

app.directive('resize', resizeDirective);
app.directive('on-clickaway', onClickaway);

sync(store, router);
// load common helpers into js
commonHelpers();

window.WootConstants = constants;
window.axios = createAxios(axios);
// [VITE] Disabled this we don't need it, we can use `useEmitter` directly
// app.prototype.$emitter = emitter;

initializeChatwootEvents();
initializeAnalyticsEvents();
initalizeRouter();

window.onload = () => {
  app.mount('#app');
};

window.addEventListener('load', () => {
  window.playAudioAlert = () => {};
});