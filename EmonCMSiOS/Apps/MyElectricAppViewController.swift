//
//  MyElectricAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

class MyElectricAppViewController: UIViewController, AppViewController {

  var viewModel: MyElectricAppViewModel!

  var genericViewModel: AppViewModel! {
    get {
      return self.viewModel
    }
    set(vm) {
      self.viewModel = vm as! MyElectricAppViewModel
    }
  }

  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var usageTodayLabel: UILabel!
  @IBOutlet fileprivate var lineChart: LineChartView!
  @IBOutlet fileprivate var barChart: BarChartView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "My Electric"

    self.setupCharts()
    self.setupBindings()

    self.viewModel.updatePowerAndUsage().subscribe().addDisposableTo(self.disposeBag)
    self.viewModel.updateChartData().subscribe().addDisposableTo(self.disposeBag)

  }

  private func setupBindings() {
    self.viewModel.powerNow
      .asDriver()
      .map { $0.prettyFormat() + "W" }
      .drive(self.powerLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.usageToday
      .asDriver()
      .map { $0.prettyFormat() + "kWh" }
      .drive(self.usageTodayLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.lineChartData
      .asDriver()
      .drive(onNext: { [weak self] feedDataPoints in
        guard let strongSelf = self else { return }

        guard let data = strongSelf.lineChart.data,
          let dataSet = data.getDataSetByIndex(0) else {
            return
        }

        data.xVals = []
        dataSet.clear()

        for (i, point) in feedDataPoints.enumerated() {
          data.addXValue("\(point.time.timeIntervalSince1970)")

          let yDataEntry = ChartDataEntry(value: point.value, xIndex: i)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        data.notifyDataChanged()
        strongSelf.lineChart.notifyDataSetChanged()
        })
      .addDisposableTo(self.disposeBag)

    self.viewModel.barChartData
      .asDriver()
      .drive(onNext: { [weak self] feedDataPoints in
        guard let strongSelf = self else { return }

        guard let data = strongSelf.barChart.data,
          let dataSet = data.getDataSetByIndex(0) else {
            return
        }

        data.xVals = []
        dataSet.clear()

        for (i, point) in feedDataPoints.enumerated() {
          data.addXValue("\(point.time.timeIntervalSince1970)")

          let yDataEntry = BarChartDataEntry(value: point.value, xIndex: i)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        data.notifyDataChanged()
        strongSelf.barChart.notifyDataSetChanged()
        })
      .addDisposableTo(self.disposeBag)
  }

}

extension MyElectricAppViewController {

  fileprivate func setupCharts() {
    self.setupLineChart()
    self.setupBarChart()
  }

  fileprivate func setupLineChart() {
    guard let lineChart = self.lineChart else {
      return
    }

    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false
    lineChart.descriptionText = ""
    lineChart.noDataText = ""

    let xAxis = lineChart.xAxis
    xAxis.drawAxisLineEnabled = false
    xAxis.drawGridLinesEnabled = false
    xAxis.drawLabelsEnabled = false
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .lightGray
    xAxis.spaceBetweenLabels = 0

    let yAxis = lineChart.leftAxis
    yAxis.labelPosition = .insideChart
    yAxis.drawTopYLabelEntryEnabled = false
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.labelTextColor = .lightGray

    let dataSet = LineChartDataSet()
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.fillColor = EmonCMSColors.Chart.Blue
    dataSet.valueTextColor = .lightGray
    dataSet.drawFilledEnabled = true
    dataSet.drawCirclesEnabled = false
    dataSet.drawValuesEnabled = false
    dataSet.highlightEnabled = false

    let data = LineChartData()
    data.addDataSet(dataSet)
    lineChart.data = data
  }

  fileprivate func setupBarChart() {
    guard let barChart = self.barChart else {
      return
    }

    barChart.drawGridBackgroundEnabled = false
    barChart.legend.enabled = false
    barChart.leftAxis.enabled = false
    barChart.rightAxis.enabled = false
    barChart.descriptionText = ""
    barChart.noDataText = ""
    barChart.isUserInteractionEnabled = false
    barChart.extraBottomOffset = 2

    let xAxis = barChart.xAxis
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .lightGray
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.valueFormatter = ChartXAxisDateFormatter()

    let dataSet = BarChartDataSet(yVals: nil, label: "kWh")
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.valueTextColor = .lightGray

    let data = BarChartData()
    data.addDataSet(dataSet)
    barChart.data = data
  }

}