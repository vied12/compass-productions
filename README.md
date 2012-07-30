# Portfolio

# A Serious Toolkit

## Preprocessor and static files collection

You must never add manually files in `static` and `templates`.

* Template files are generated at each request by the shpaml preprocessor from `lib/shpaml` to `templates`
* JS files are generated at each request by the coffeescript preprocessor from `lib/coffee` to `static\js`
* CSS files are generated at each request by the CleverCSS preprocessor from `lib/ccss` to `static\css`

Others static files should be collected with the command

`python webapp.py collectstatic`

then  all files in `lib/images`, `lib/js` and `lib/css` are copied in `static`

## Run application

just launch `python webapp.py`
and go there `http://localhost:5000`