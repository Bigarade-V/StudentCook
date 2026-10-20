import { Recipe } from '../model/Recipe'
import { RecipeRepository } from '../model/RecipeRepository'
import { RecipeImage } from '../components/RecipeImage'

const COLOR_PRIMARY: string = '#F4511E'

@Builder
export function CategoryPageBuilder() {
  CategoryPage()
}

/**
 * 分类页: 左侧分类导航 + 右侧 List + ListItemGroup 二级联动
 * List 的子组件索引规则: ListItemGroup 整体算一个索引,
 * 因此 onScrollIndex 的 start 即为当前可见分类的索引
 */
@Component
struct CategoryPage {
  @State currentGroupIndex: number = 0
  private repo: RecipeRepository = RecipeRepository.getInstance()
  private categories: string[] = []
  private recipesByCategory: Recipe[][] = []
  private leftScroller: Scroller = new Scroller()
  private rightScroller: ListScroller = new ListScroller()
  private pathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.categories = this.repo.getCategories()
    for (const cat of this.categories) {
      this.recipesByCategory.push(this.repo.getByCategory(cat))
    }
  }

  build() {
    NavDestination() {
      Row() {
        List({ scroller: this.leftScroller }) {
          ForEach(this.categories, (cat: string, index: number) => {
            ListItem() {
              Text(cat)
                .fontSize(14)
                .fontColor(this.currentGroupIndex === index ? COLOR_PRIMARY : '#4E5969')
                .fontWeight(this.currentGroupIndex === index ? FontWeight.Bold : FontWeight.Normal)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 14, bottom: 14 })
                .backgroundColor(this.currentGroupIndex === index ? Color.White : '#F5F6F8')
                .onClick(() => {
                  this.currentGroupIndex = index
                  this.rightScroller.scrollToItemInGroup(index, 0, true, ScrollAlign.START)
                })
            }
          }, (cat: string) => cat)
        }
        .width(96)
        .height('100%')
        .backgroundColor('#F5F6F8')
        .scrollBar(BarState.Off)

        List({ scroller: this.rightScroller }) {
          ForEach(this.categories, (cat: string, groupIndex: number) => {
            ListItemGroup({ header: this.groupHeader(cat) }) {
              ForEach(this.recipesByCategory[groupIndex], (item: Recipe) => {
                ListItem() {
                  this.recipeRow(item)
                }
              }, (item: Recipe) => item.id)
            }
          }, (cat: string) => cat)
        }
        .layoutWeight(1)
        .height('100%')
        .sticky(StickyStyle.Header)
        .scrollBar(BarState.Off)
        .onScrollIndex((start: number) => {
          if (start !== this.currentGroupIndex) {
            this.currentGroupIndex = start
            this.leftScroller.scrollToIndex(start, true, ScrollAlign.CENTER)
          }
        })
      }
      .width('100%')
      .height('100%')
    }
    .title('全部分类')
    .backgroundColor('#F5F6F8')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack
    })
  }

  @Builder
  groupHeader(cat: string) {
    Text(cat)
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1F2329')
      .width('100%')
      .padding({ top: 12, bottom: 8, left: 12 })
      .backgroundColor('#F5F6F8')
  }

  @Builder
  recipeRow(item: Recipe) {
    Row({ space: 10 }) {
      RecipeImage({
        imageUrl: item.imageUrl,
        label: item.name,
        category: item.category,
        imgWidth: 64,
        imgHeight: 64,
        radius: 8
      })
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 8 }) {
          Text(Recipe.stars(item.difficulty))
            .fontSize(12)
            .fontColor(COLOR_PRIMARY)
          Text(item.cookingTime)
            .fontSize(12)
            .fontColor('#86909C')
          Text(`${item.steps.length} 步`)
            .fontSize(12)
            .fontColor('#86909C')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .onClick(() => {
      this.pathStack.pushPathByName('DetailPage', item.id)
    })
  }
}
