import { Recipe } from '../model/Recipe'
import { RecipeRepository } from '../model/RecipeRepository'
import { FavoritesStore } from '../model/FavoritesStore'
import { RecipeImage } from '../components/RecipeImage'

const COLOR_PRIMARY: string = '#F4511E'

@Builder
export function FavoritesPageBuilder() {
  FavoritesPage()
}

/**
 * 收藏页: 由 AppStorage('favoriteIds') 驱动, @Watch 联动刷新列表
 */
@Component
struct FavoritesPage {
  @StorageProp('favoriteIds') @Watch('onFavoritesChanged') favoriteIds: string[] = []
  @State favRecipes: Recipe[] = []
  private repo: RecipeRepository = RecipeRepository.getInstance()
  private pathStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.refresh()
  }

  onFavoritesChanged(): void {
    this.refresh()
  }

  private refresh(): void {
    const list: Recipe[] = []
    for (const id of this.favoriteIds) {
      const r: Recipe | null = this.repo.getById(id)
      if (r !== null) {
        list.push(r)
      }
    }
    this.favRecipes = list
  }

  build() {
    NavDestination() {
      if (this.favRecipes.length === 0) {
        Column({ space: 8 }) {
          Text('暂无收藏')
            .fontSize(15)
            .fontColor('#86909C')
          Text('在菜谱详情中点击收藏即可添加')
            .fontSize(12)
            .fontColor('#A9AEB8')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.favRecipes, (item: Recipe) => {
            ListItem() {
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
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('取消收藏')
                  .fontSize(12)
                  .fontColor('#86909C')
                  .padding(8)
                  .onClick(() => {
                    const store: FavoritesStore | null = FavoritesStore.peek()
                    if (store !== null) {
                      store.toggle(item.id)
                    }
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onClick(() => {
                this.pathStack.pushPathByName('DetailPage', item.id)
              })
            }
          }, (item: Recipe) => item.id)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 12, right: 12, top: 12 })
        .scrollBar(BarState.Off)
      }
    }
    .title('我的收藏')
    .backgroundColor('#F5F6F8')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack
    })
  }
}
