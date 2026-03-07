# Jikan

To start your Phoenix server:


```bash
# on local run
ssh root@157.180.64.13 "docker run --rm -v jikan_data:/data -v \$(pwd):/backup alpine tar czf /backup/jikan_backup.tar.gz -C /data ."
1# Then copy the tar file
scp root@157.180.64.13:/root/jikan_backup.tar.gz ./data_backup/
```

scp "root@157.180.64.13:/var/lib/docker/volumes/jikan_data/_data/*.*" ./data_backup/

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
