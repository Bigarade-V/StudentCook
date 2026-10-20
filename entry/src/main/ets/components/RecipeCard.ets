import { Recipe } from '../model/Recipe'
import { RecipeImage } from './RecipeImage'

const COLOR_PRIMARY: string = '#F4511E'
const COLOR_TEXT_MAIN: string = '#1F2329'
const COLOR_TEXT_SUB: string = '#86909C'

/**
 * 瀑布流卡片: 封面图高度随步骤数变化, 形成高低错落的双列瀑布流
 */
@Component
export struct RecipeCard {
  recipe: Recipe = new Recipe('', '', '', [], [], '', 0, '')
  onItemClick: (recipe: Recipe) => void = (recipe: Recipe) => {}

  private cardImageHeight(): number {
    return 92 + Math.min(this.recipe.steps.length, 8) * 8
  }

  build() {
    Column() {
      RecipeImage({
        imageUrl: this.recipe.imageUrl,
        label: this.recipe.name,
        category: this.recipe.category,
        imgHeight: this.cardImageHeight(),
        radius: 0
      })
      Column({ space: 6 }) {
        Text(this.recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Row({ space: 6 }) {
          Text(Recipe.stars(this.recipe.difficulty))
            .fontSize(12)
            .fontColor(COLOR_PRIMARY)
          Text(this.recipe.cookingTime)
            .fontSize(12)
            .fontColor(COLOR_TEXT_SUB)
        }
        .width('100%')
        Text(`${this.recipe.category} · 共 ${this.recipe.steps.length} 步`)
          .fontSize(12)
          .fontColor(COLOR_TEXT_SUB)
          .maxLines(1)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
      .width('100%')
    }
    .borderRadius(12)
    .backgroundColor(Color.White)
    .clip(true)
    .onClick(() => {
      this.onItemClick(this.recipe)
    })
  }
}
