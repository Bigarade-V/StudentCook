/**
 * 菜谱封面图: 本地图用 $rawfile, 网络图直接加载, 均失败或无图时显示分类色占位块
 */
const CATEGORY_COLORS: Record<string, string> = {
  '早餐': '#FF9800',
  '荤菜': '#EF5350',
  '素菜': '#66BB6A',
  '水产': '#26A69A',
  '汤类': '#8D6E63',
  '主食': '#FFB300',
  '甜品': '#EC407A',
  '饮品': '#7E57C2',
  '调料': '#78909C',
  '半成品': '#5C6BC0'
}

@Component
export struct RecipeImage {
  @Prop @Watch('onUrlChange') imageUrl: string = ''
  @State loadFailed: boolean = false
  label: string = ''
  category: string = ''
  imgWidth: Length = '100%'
  imgHeight: Length = 110
  radius: number = 0

  onUrlChange(): void {
    this.loadFailed = false
  }

  private placeholderColor(): string {
    const c: string | undefined = CATEGORY_COLORS[this.category]
    return c ?? '#86909C'
  }

  private placeholderChar(): string {
    if (this.label !== '') {
      return this.label.charAt(0)
    }
    if (this.category !== '') {
      return this.category.charAt(0)
    }
    return '菜'
  }

  private placeholderCharSize(): number {
    const h: number = Number(this.imgHeight)
    if (Number.isNaN(h)) {
      return 28
    }
    return Math.max(20, Math.min(72, Math.round(h / 4)))
  }

  build() {
    if (this.imageUrl !== '' && !this.loadFailed) {
      if (this.imageUrl.startsWith('http')) {
        Image(this.imageUrl)
          .width(this.imgWidth)
          .height(this.imgHeight)
          .objectFit(ImageFit.Cover)
          .borderRadius(this.radius)
          .draggable(false)
          .onError(() => {
            this.loadFailed = true
          })
      } else {
        Image($rawfile(this.imageUrl))
          .width(this.imgWidth)
          .height(this.imgHeight)
          .objectFit(ImageFit.Cover)
          .borderRadius(this.radius)
          .draggable(false)
          .onError(() => {
            this.loadFailed = true
          })
      }
    } else {
      Column() {
        Text(this.placeholderChar())
          .fontSize(this.placeholderCharSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.placeholderColor())
      }
      .width(this.imgWidth)
      .height(this.imgHeight)
      .backgroundColor('#26' + this.placeholderColor().slice(1))
      .borderRadius(this.radius)
      .justifyContent(FlexAlign.Center)
    }
  }
}
