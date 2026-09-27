# Editing the academic site

The site remains a static Jekyll site with local CSS and a small, dependency-free JavaScript file. Existing publication and news URLs are preserved.

## Add a research work

1. Add English and Chinese Markdown entries under `_publications/`, following an existing pair. Both entries must share a unique `work_id`; preserve published permalinks when updating existing records.
2. Add that ID to `_data/works.yml`. This shared record controls the publication year, topic, full author line, preprint status, and optional verified BibTeX. The `date` in Markdown is the documented publication or first-public-release date used for recency (not a later database ingestion date; C_D uses 2023-03-25, not Wanfang’s 2023-04-03); `year` is the year of the cited publication. EESD, for example, was online in 2024 and published in the 2025 issue.
3. Use `firstauthor`, `cofirst`, or `correspondingauthor` only when supported by the paper. First/co-first statistics count their union, once per English record. Corresponding-author counts also use one English record per work with the `correspondingauthor` tag; the home statistic links to `?role=corresponding`. Preprints are included in the total works count and explicitly labeled. A later published version should update the same work, not create a duplicate.
4. Use a real figure, put it in `images/`, and reference its filename in `header.teaser`. This field is optional. Do not stretch images or fabricate an interface.
5. Only add BibTeX when authors, title, year, and venue/identifier are verified. Omit unavailable fields; escape TeX characters such as `&` as `\&`. Citation text can always be copied without BibTeX.

Years, year counts, totals, and latest works are generated from the actual data. No yearly template edit is needed. The home page's notes come from the actual bilingual `_posts` records, not invented release events.

## Projects and translations

`_data/projects.yml` defines the three featured projects and their real resources. Shared IDs, assets, and destinations sit next to bilingual copy. HouseMind links to its resource page, not to an unavailable code release. `_data/design.yml` contains the new interface text.

`_layouts/default.html` is the shared shell; `single.html` handles paper/news details and `archive.html` handles lists and the CV. The new design uses `assets/css/site.css` and `assets/js/site.js`, without external fonts or UI libraries. The previous theme assets remain in Git for reference.

## New image provenance

- `images/2026-07-16-StructureClaw.png`: https://arxiv.org/html/2607.14896v2/framework-t.png
- `images/structureclaw-project.png`: https://arxiv.org/html/2607.14896v2/teaser-t.png
- Other project images are the existing original paper figures, reused without changing their content.

## Validate

```sh
bundle exec ruby scripts/check_content.rb
node --check assets/js/site.js
bundle exec jekyll build --config _config.yml,_config_prod.yml
bundle exec jekyll build
```

The first build configuration targets `qinsizhong.com`; the second keeps the GitHub Pages `/qsz_academic` subpath. Check both when changing URLs. The CV has a print stylesheet. With JavaScript disabled, all works, year anchors, summaries, citation text, and ordinary links remain accessible.
