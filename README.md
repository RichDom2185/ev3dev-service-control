# ev3dev-service-control

A GUI application to control running services on the EV3. Tailored to the [EV3-source](https://github.com/source-academy/ev3-source) image used in Source Academy@NUS.

## Building

```bash
docker build -t compiler .
docker run --rm -v "$(pwd)":/src -w /src -u 0:0 compiler -o bin main.vala
```
