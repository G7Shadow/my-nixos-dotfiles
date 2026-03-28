import app from "ags/gtk4/app"
import style from "./style.scss"
import colors from "./colors/colors.css"
import Bar from "./widget/Bar"

app.start({
  css: `${colors}\n${style}`,
  gtkTheme: "Adwaita-dark",
  main() {
    Bar()
  },
})
