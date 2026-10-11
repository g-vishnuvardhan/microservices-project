# Design references and decisions

The interface is an original implementation inspired by the following galleries. Their artwork, source files and exact layouts were not copied.

- [Dribbble: E-commerce Analytics Dashboard / Seller Admin Panel UI, Orbix Studio](https://dribbble.com/shots/27146968-E-commerce-Analytics-Dashboard-Seller-Admin-Panel-UI): clear hierarchy, restrained dashboard navigation, easy-to-scan product and activity information.
- [Dribbble e-commerce dashboard gallery](https://dribbble.com/search/Ecommerce-dashboard): compact navigation and consistent content spacing.
- [Collect UI designs gallery](https://collectui.com/designs): reference for familiar shopping/cart patterns. The requested `collectui.in` address could not be loaded during research; the available Collect UI gallery was used instead.

## CloudMart visual system

- Warm off-white background with sage accents and charcoal-green text.
- Manrope headings and DM Sans body text, with Arial fallbacks for offline use.
- Pastel product illustrations drawn specifically for this project as lightweight inline SVG.
- One active navigation state, category selection, search, a persistent bag and an explicit checkout action.
- Visible loading, empty, error and success states. Unavailable services do not silently switch to invented data.
- A dark theme, visible keyboard focus, semantic buttons, labelled quantity controls, live status messages and reduced-motion support.
- Responsive layouts: desktop sidebar and product/cart columns, stacked cart at narrower widths, horizontal navigation on phones.

The service inspector stays separate from shopping so a user can complete checkout without understanding infrastructure. The college demo guide provides technical detail when needed.
