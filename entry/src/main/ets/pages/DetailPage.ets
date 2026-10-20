import { Recipe } from '../model/Recipe'
import { RecipeRepository } from '../model/RecipeRepository'
import { FavoritesStore } from '../model/FavoritesStore'
import { RecipeImage } from '../components/RecipeImage'

const COLOR_PRIMARY: string = '#F4511E'

@Builder
export function DetailPageBuilder() {
  DetailPage()
}

/**
 * 详情页: 封面大图 + 难度/时长/分类 + 收藏 + 用料 + 可折叠步骤面板
 */
@Component
struct DetailPage {
  @State recipe: Recipe = new Recipe('', '', '', [], [], '', 0, '')
  @State expandedStep: number = 0
  @StorageProp('favoriteIds') favoriteIds: string[] = []
  private recipeId: string = ''
  private repo: RecipeRepository = RecipeRepository.getInstance()
  private pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      if (this.recipe.id === '') {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#86909C')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            RecipeImage({
              imageUrl: this.recipe.imageUrl,
              label: this.recipe.name,
              category: this.recipe.category,
              imgHeight: 230,
              radius: 0
            })
            Column({ space: 10 }) {
              Text(this.recipe.name)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F2329')
                .width('100%')
              Row({ space: 10 }) {
                Text(this.recipe.category)
                  .fontSize(12)
                  .fontColor(COLOR_PRIMARY)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor('#FDEBE4')
                  .borderRadius(10)
                Text(Recipe.stars(this.recipe.difficulty))
                  .fontSize(13)
                  .fontColor(COLOR_PRIMARY)
                Text(this.recipe.cookingTime)
                  .fontSize(13)
                  .fontColor('#86909C')
              }
              .width('100%')

              Button(this.favoriteIds.includes(this.recipeId) ? '已收藏' : '收藏')
                .fontSize(14)
                .fontColor(this.favoriteIds.includes(this.recipeId) ? Color.White : COLOR_PRIMARY)
                .backgroundColor(this.favoriteIds.includes(this.recipeId) ? COLOR_PRIMARY : Color.White)
                .borderRadius(18)
                .height(36)
                .padding({ left: 24, right: 24 })
                .margin({ top: 4 })
                .onClick(() => {
                  const store: FavoritesStore | null = FavoritesStore.peek()
                  if (store !== null) {
                    store.toggle(this.recipeId)
                  }
                })

              this.sectionTitle('用料')
              Column({ space: 8 }) {
                ForEach(this.recipe.ingredients, (ing: string) => {
                  Row({ space: 8 }) {
                    Column()
                      .width(5)
                      .height(5)
                      .borderRadius(3)
                      .backgroundColor('#C9CDD4')
                      .margin({ top: 8 })
                    Text(ing)
                      .fontSize(14)
                      .fontColor('#4E5969')
                      .lineHeight(20)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)
                }, (ing: string) => ing)
              }
              .width('100%')
              .padding(12)
              .borderRadius(12)
              .backgroundColor(Color.White)

              this.sectionTitle('步骤')
              Column({ space: 10 }) {
                ForEach(this.recipe.steps, (step: string, index: number) => {
                  this.stepPanel(index, step)
                }, (step: string, index: number) => `${index}-${step.length}`)
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(14)
            .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
      }
    }
    .title(this.recipe.id === '' ? '菜谱详情' : this.recipe.name)
    .backgroundColor('#F5F6F8')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack
      if (typeof ctx.pathInfo.param === 'string') {
        this.recipeId = ctx.pathInfo.param
        const loaded: Recipe | null = this.repo.getById(ctx.pathInfo.param)
        if (loaded !== null) {
          this.recipe = loaded
          this.expandedStep = 0
        }
      }
    })
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1F2329')
      .margin({ top: 6 })
  }

  @Builder
  stepPanel(index: number, step: string) {
    Column({ space: 8 }) {
      Row() {
        Text(`${index + 1}`)
          .fontSize(13)
          .fontColor(Color.White)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor(COLOR_PRIMARY)
        Text(step.split('\n')[0])
          .fontSize(14)
          .fontColor('#1F2329')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 8, right: 8 })
        Text(this.expandedStep === index ? '收起' : '展开')
          .fontSize(12)
          .fontColor('#86909C')
      }
      .width('100%')
      .onClick(() => {
        if (this.expandedStep === index) {
          this.expandedStep = -1
        } else {
          this.expandedStep = index
        }
      })

      if (this.expandedStep === index) {
        Text(step)
          .fontSize(14)
          .fontColor('#4E5969')
          .lineHeight(22)
          .width('100%')
          .padding({ left: 28, right: 4, bottom: 4 })
      }
    }
    .borderRadius(12)
    .backgroundColor(Color.White)
    .padding(12)
    .width('100%')
  }
}
