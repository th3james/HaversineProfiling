# Haversine

Calculate haversine distances from coordinate pairs. Homework for [Computer, Enhance!](https://www.computerenhance.com/)

## Usage

Build the project:
```sh
zig build
```

Generate an input file with random coordinate pairs:
```sh
./zig-out/bin/haversine generate <filename> <point_count>
```

Calculate haversine distances from the input file:
```sh
./zig-out/bin/haversine parse <filename>
```

## Example

```sh
./zig-out/bin/haversine generate data.json 10000
./zig-out/bin/haversine parse data.json
```
