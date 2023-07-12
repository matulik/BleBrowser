// from https://github.com/tottokotkd/PopUpPickerView

import UIKit

// MARK: - PopUpPickerView
class PopUpPickerView: UIView {
    var pickerView: UIPickerView!
    var pickerToolbar: UIToolbar!
    var toolbarItems: [UIBarButtonItem]!
    
    var delegate: PopUpPickerViewDelegate? {
        didSet {
            pickerView.delegate = delegate
            pickerView.dataSource = delegate
        }
    }

    private var selectedRows: [Int]?

    // MARK: Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        initFunc()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        initFunc()
    }

    private func initFunc() {
        let screenSize = UIScreen.main.bounds.size
        backgroundColor = UIColor.black

        pickerToolbar = UIToolbar()
        pickerView = UIPickerView()
        toolbarItems = []

        pickerToolbar.isTranslucent = true
        pickerView.showsSelectionIndicator = true
        pickerView.backgroundColor = UIColor.white

        bounds = CGRectMake(0, 0, screenSize.width, 260)
        frame = CGRectMake(0, screenSize.height, screenSize.width, 260)
        pickerToolbar.bounds = CGRectMake(0, 0, screenSize.width, 44)
        pickerToolbar.frame = CGRectMake(0, 0, screenSize.width, 44)
        pickerView.bounds = CGRectMake(0, 0, screenSize.width, 216)
        pickerView.frame = CGRectMake(0, 44, screenSize.width, 216)

        let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        space.width = 12
        let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(cancelPicker))
        let flexSpaceItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(endPicker))
        toolbarItems! += [space, cancelItem, flexSpaceItem, doneButtonItem, space]

        pickerToolbar.setItems(toolbarItems, animated: false)
        addSubview(pickerToolbar)
        addSubview(pickerView)
    }

    func showPicker() {
        if selectedRows == nil {
            selectedRows = getSelectedRows()
        }
        let screenSize = UIScreen.main.bounds.size
        UIView.animate(withDuration: 0.2) {
            self.frame = CGRectMake(0, screenSize.height - 260.0, screenSize.width, 260.0)
        }
    }

    @objc func cancelPicker() {
        hidePicker()
        restoreSelectedRows()
        selectedRows = nil
    }

    @objc func endPicker() {
        hidePicker()
        delegate?.pickerView?(pickerView: pickerView, didSelect: getSelectedRows())
        selectedRows = nil
    }

    func updatePicker() {
        pickerView.reloadAllComponents()
    }

    private func hidePicker() {
        let screenSize = UIScreen.main.bounds.size
        UIView.animate(withDuration: 0.2) {
            self.frame = CGRectMake(0, screenSize.height, screenSize.width, 260.0)
        }
    }

    private func getSelectedRows() -> [Int] {
        var selectedRows = [Int]()
        for i in 0 ..< pickerView.numberOfComponents {
            selectedRows.append(pickerView.selectedRow(inComponent: i))
        }
        return selectedRows
    }

    private func restoreSelectedRows() {
        for i in 0 ..< selectedRows!.count {
            pickerView.selectRow(selectedRows![i], inComponent: i, animated: true)
        }
    }
}

// MARK: - PopUpPickerViewDelegate
@objc
protocol PopUpPickerViewDelegate: UIPickerViewDelegate, UIPickerViewDataSource {
    @objc optional func pickerView(pickerView: UIPickerView, didSelect numbers: [Int])
}
