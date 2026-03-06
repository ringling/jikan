defmodule Jikan.Release do
  @app :jikan

  def migrate do
    load_app()
    
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed(file \\ "seeds.exs") do
    load_app()
    
    # Use Ecto.Migrator.with_repo to properly start just the repo
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn _repo ->
        seed_file = Path.join([:code.priv_dir(@app), "repo", file])
        
        if File.exists?(seed_file) do
          Code.eval_file(seed_file)
          IO.puts("Seeds from #{file} executed successfully")
        else
          IO.puts("Seed file not found: #{seed_file}")
        end
      end)
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end