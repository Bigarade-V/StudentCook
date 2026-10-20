import { Recipe } from '../model/Recipe'
import { RecipeRepository } from '../model/RecipeRepository'
import { RecipeDataSource } from '../model/RecipeDataSource'
import { RecipeCard } from '../components/RecipeCard'

/**
 * 首页: 顶部搜索框(按名称过滤) + 双列瀑布流(WaterFlow + LazyForEach)
 */
@Entry
@Component
struct Index {
  @State resultCount: number = 0
  private pathStack: NavPathStack = new NavPathStack()
  private repo: RecipeRepository = RecipeRepository.getInstance()
  private dataSource: RecipeDataSource = new RecipeDataSource(this.repo.getAll())

  aboutToAppear(): void {
    this.resultCount = this.dataSource.totalCount()
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        Row({ space: 12 }) {
          TextInput({ placeholder: '搜索菜谱名称' })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .placeholderColor('#9AA0A6')
            .backgroundColor('#F1F2F4')
            .borderRadius(20)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              const result: Recipe[] = this.repo.search(value)
              this.dataSource.update(result)
              this.resultCount = result.length
            })
          Text('分类')
            .fontSize(14)
            .fontColor('#F4511E')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.pathStack.pushPathByName('CategoryPage', null)
            })
          Text('收藏')
            .fontSize(14)
            .fontColor('#F4511E')
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.pathStack.pushPathByName('FavoritesPage', null)
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })

        if (this.resultCount === 0) {
          Column() {
            Text('没有找到匹配的菜谱')
              .fontSize(14)
              .fontColor('#86909C')
              .margin({ top: 120 })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          WaterFlow() {
            LazyForEach(this.dataSource, (item: Recipe) => {
              FlowItem() {
                RecipeCard({
                  recipe: item,
                  onItemClick: (r: Recipe) => {
                    this.pathStack.pushPathByName('DetailPage', r.id)
                  }
                })
              }
            }, (item: Recipe) => item.id)
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .padding({ left: 12, right: 12, bottom: 12 })
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .backgroundColor('#F5F6F8')
  }
}
