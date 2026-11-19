/* Town Center ad pages: runtime configuration.
   Nothing loads and nothing is sent while an ID or endpoint is empty. This file is public:
   never put secrets in it. */
window.TC_CONFIG = {
  FORM_ENDPOINT: "",          /* POST (JSON) target. Empty = demo thank-you, nothing is sent. */
  GTM_ID: "",                 /* e.g. "GTM-XXXXXXX". If set, ONLY GTM loads (direct snippets below are skipped). */
  /* Direct snippets: used only when GTM_ID is empty */
  GA4_ID: "",                 /* e.g. "G-XXXXXXXXXX" */
  GADS_ID: "",                /* e.g. "AW-123456789" */
  GADS_LABEL: "",             /* conversion label, e.g. "AbC-D_efG-h12" */
  META_PIXEL_ID: "",
  SNAP_PIXEL_ID: "",
  LINKEDIN_ID: "",            /* LinkedIn Insight partner id */
  LINKEDIN_CONVERSION_ID: "", /* optional: LinkedIn conversion rule id fired on submit */
  /* Direct phone/email block (clicks are tracked as events). Default OFF for ad pages. */
  SHOW_DIRECT_CONTACT: false,
  CONTACT_PHONE: "+966114446669",
  CONTACT_PHONE_LABEL: "+966 11 444 666 9",
  CONTACT_EMAIL: "info@blacksand.sa"
};
