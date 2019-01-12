# Create hex sticker

library(hexSticker)

sticker <- function(subplot, s_x = 0.8, s_y = 0.75, s_width = 0.4, s_height = 0.5,
                     package, p_x = 1, p_y = 1.4, p_color = "#FFFFFF", p_family = "Aller_Rg",
                     p_size = 8, h_size = 1.2, h_fill = "#1881C2", h_color = "#87B13F",
                     spotlight = FALSE, l_x = 1, l_y = 0.5, l_width = 3, l_height = 3,
                     l_alpha = 0.4, url = "", u_x = 1, u_y = 0.08, u_color = "black",
                     u_family = "Aller_Rg", u_size = 1.5, filename = paste0(package,
                                                                            ".png"), dpi = 300) {
  sticker <- hexagon(size = h_size, fill = h_fill, color = h_color)
  # if (inherits(subplot, "character")) {
  #   d <- data.frame(x = s_x, y = s_y, image = subplot)
  #   sticker <- hex + geom_image(aes_(x = ~x, y = ~y, image = ~image),
  #                               d, size = s_width)
  # }
  # else {
  #   sticker <- hex + geom_subview(subview = subplot, x = s_x,
  #                                 y = s_y, width = s_width, height = s_height)
  # }
  if (spotlight)
    sticker <- sticker + geom_subview(subview = spotlight(l_alpha),
                                      x = l_x, y = l_y, width = l_width, height = l_height)
  sticker <- sticker + geom_pkgname(package, p_x, p_y, p_color,
                                    p_family, p_size)
  sticker <- sticker + geom_url(url, x = u_x, y = u_y, color = u_color,
                                family = u_family, size = u_size)
  save_sticker(filename, sticker, dpi = dpi)
  invisible(sticker)
}

sticker(NULL, package = "altituder", p_size = 20, p_color = "#000000",
        h_fill = "#FFAACC", h_color = "#112233",
        s_x = 1, s_y = .75, s_width = 1.3, s_height = 1,
        p_x = 1, p_y = 1,
        filename = "public/images/hex-altituder.png")


sticker(NULL, package = "pkghelper", p_size = 20, p_color = "#FFFFFF",
        h_fill = "#0842a0", h_color = "#112233",
        s_x = 1, s_y = .75, s_width = 1.3, s_height = 1,
        p_x = 1, p_y = 1,
        filename = "public/images/hex-pkghelper.png")


hexSticker::sticker("public/images/reinforcelearn-logo.png", package = "", p_size = 18, p_color = "#000000",
        h_fill = "#FFFFFF", h_color = "#0842a0",
        s_x = 1, s_y = 1, s_width = 0.9, s_height = 1,
        p_x = 1, p_y = 1,
        filename = "public/images/hex-reinforcelearn.png")
